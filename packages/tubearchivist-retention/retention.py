#!/usr/bin/env python3
"""Keep a TubeArchivist media directory below a configured size."""

from __future__ import annotations

import argparse
import fcntl
import json
import os
from dataclasses import dataclass
from pathlib import Path
import sys
from typing import Callable, Iterable
import urllib.error
import urllib.parse
import urllib.request


class RetentionError(RuntimeError):
    """A safe, operator-facing retention failure."""


@dataclass(frozen=True)
class Video:
    youtube_id: str
    title: str
    published: str
    media_size: int
    watched: bool


@dataclass(frozen=True)
class RetentionResult:
    before_bytes: int
    after_bytes: int
    deleted_ids: tuple[str, ...]
    over_limit: bool
    dry_run: bool


def format_bytes(value: int) -> str:
    """Format bytes as GiB for concise logs."""

    return f"{value / (1024**3):.2f} GiB"


def directory_size(path: Path) -> int:
    """Return logical file size without following symlinks."""

    if not path.is_dir():
        raise RetentionError(f"media directory does not exist: {path}")

    total = 0
    pending = [path]
    while pending:
        current = pending.pop()
        try:
            entries = list(os.scandir(current))
        except OSError as exc:
            raise RetentionError(f"cannot scan media directory: {exc}") from exc

        for entry in entries:
            try:
                if entry.is_symlink():
                    continue
                if entry.is_dir(follow_symlinks=False):
                    pending.append(Path(entry.path))
                elif entry.is_file(follow_symlinks=False):
                    total += entry.stat(follow_symlinks=False).st_size
            except FileNotFoundError:
                # TubeArchivist may atomically rename a completed download.
                continue
            except OSError as exc:
                raise RetentionError(f"cannot inspect media file: {exc}") from exc

    return total


def load_token(path: Path) -> str:
    """Load a TubeArchivist API token from a runtime-only file."""

    try:
        token = path.read_text(encoding="utf-8").strip()
    except OSError as exc:
        raise RetentionError(f"cannot read API token file: {path}") from exc

    if not token:
        raise RetentionError(f"API token file is empty: {path}")

    return token


class TubeArchivistClient:
    """Minimal client for listing and deleting TubeArchivist videos."""

    def __init__(self, base_url: str, token: str, timeout_seconds: int = 30):
        self.base_url = base_url.rstrip("/")
        self.token = token
        self.timeout_seconds = timeout_seconds

    def _request(self, path: str, method: str = "GET") -> tuple[int, bytes]:
        request = urllib.request.Request(
            f"{self.base_url}{path}",
            method=method,
            headers={"Authorization": f"Token {self.token}"},
        )
        try:
            with urllib.request.urlopen(
                request, timeout=self.timeout_seconds
            ) as response:
                return response.status, response.read()
        except urllib.error.HTTPError as exc:
            raise RetentionError(
                f"TubeArchivist API {method} {path} returned HTTP {exc.code}"
            ) from exc
        except urllib.error.URLError as exc:
            raise RetentionError(
                f"TubeArchivist API {method} {path} is unavailable"
            ) from exc

    def _video_page(self, page: int | None = None) -> dict:
        query = {"sort": "published", "order": "asc"}
        if page is not None:
            query["page"] = str(page)
        path = f"/api/video/?{urllib.parse.urlencode(query)}"
        status, body = self._request(path)
        if status != 200:
            raise RetentionError(
                f"TubeArchivist video list returned unexpected HTTP {status}"
            )
        try:
            payload = json.loads(body)
        except (UnicodeDecodeError, json.JSONDecodeError) as exc:
            raise RetentionError("TubeArchivist returned an invalid video list") from exc
        if not isinstance(payload, dict) or not isinstance(payload.get("data"), list):
            raise RetentionError("TubeArchivist returned an unexpected video list")
        return payload

    @staticmethod
    def _parse_video(item: dict) -> Video | None:
        youtube_id = item.get("youtube_id")
        media_size = item.get("media_size")
        if not isinstance(youtube_id, str) or not youtube_id:
            return None
        if not isinstance(media_size, int) or media_size <= 0:
            return None
        player = item.get("player")
        watched = bool(player.get("watched")) if isinstance(player, dict) else False
        return Video(
            youtube_id=youtube_id,
            title=str(item.get("title") or youtube_id),
            published=str(item.get("published") or ""),
            media_size=media_size,
            watched=watched,
        )

    def list_videos(self) -> list[Video]:
        first = self._video_page()
        payloads = [first]
        pagination = first.get("paginate")
        last_page = pagination.get("last_page", 1) if isinstance(pagination, dict) else 1
        if not isinstance(last_page, int) or not 1 <= last_page <= 10000:
            raise RetentionError("TubeArchivist returned invalid pagination")

        payloads.extend(self._video_page(page) for page in range(2, last_page + 1))
        videos = []
        seen = set()
        for payload in payloads:
            for item in payload["data"]:
                if not isinstance(item, dict):
                    continue
                video = self._parse_video(item)
                if video is not None and video.youtube_id not in seen:
                    videos.append(video)
                    seen.add(video.youtube_id)
        return videos

    def delete_video(self, youtube_id: str) -> None:
        encoded_id = urllib.parse.quote(youtube_id, safe="")
        status, _ = self._request(f"/api/video/{encoded_id}/", method="DELETE")
        if status != 204:
            raise RetentionError(
                f"TubeArchivist delete returned unexpected HTTP {status}"
            )


def prioritize(videos: Iterable[Video]) -> list[Video]:
    """Delete watched videos first, oldest publication first within each group."""

    return sorted(
        videos,
        key=lambda video: (
            not video.watched,
            video.published,
            video.youtube_id,
        ),
    )


def enforce_retention(
    *,
    media_dir: Path,
    max_bytes: int,
    target_bytes: int,
    client: TubeArchivistClient,
    dry_run: bool = False,
    current_size: int | None = None,
    size_reader: Callable[[Path], int] = directory_size,
) -> RetentionResult:
    """Delete API-indexed videos until media usage reaches the low-water mark."""

    if target_bytes <= 0 or max_bytes <= 0 or target_bytes >= max_bytes:
        raise RetentionError("target size must be positive and below maximum size")

    before = size_reader(media_dir) if current_size is None else current_size
    if before <= max_bytes:
        return RetentionResult(before, before, (), False, dry_run)

    videos = prioritize(client.list_videos())
    if not videos:
        raise RetentionError("media is over limit but TubeArchivist returned no videos")

    projected = before
    deleted = []
    for video in videos:
        if projected <= target_bytes:
            break
        print(
            "retention delete "
            f"id={video.youtube_id} watched={str(video.watched).lower()} "
            f"size={format_bytes(video.media_size)} title={json.dumps(video.title)}"
        )
        if not dry_run:
            client.delete_video(video.youtube_id)
        deleted.append(video.youtube_id)
        projected = max(0, projected - video.media_size)

    if projected > target_bytes:
        raise RetentionError(
            "TubeArchivist does not contain enough indexed media to reach target"
        )

    after = projected if dry_run else size_reader(media_dir)
    if not dry_run and after > target_bytes:
        raise RetentionError(
            f"cleanup ended above target: {format_bytes(after)}"
        )

    return RetentionResult(before, after, tuple(deleted), True, dry_run)


def build_parser() -> argparse.ArgumentParser:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--media-dir", required=True, type=Path)
    parser.add_argument("--base-url", required=True)
    parser.add_argument("--token-file", required=True, type=Path)
    parser.add_argument("--max-bytes", required=True, type=int)
    parser.add_argument("--target-bytes", required=True, type=int)
    parser.add_argument("--lock-file", required=True, type=Path)
    parser.add_argument("--timeout-seconds", type=int, default=30)
    parser.add_argument("--dry-run", action="store_true")
    return parser


def main(argv: list[str] | None = None) -> int:
    args = build_parser().parse_args(argv)
    try:
        args.lock_file.parent.mkdir(parents=True, exist_ok=True)
        with args.lock_file.open("a+", encoding="utf-8") as lock:
            try:
                fcntl.flock(lock, fcntl.LOCK_EX | fcntl.LOCK_NB)
            except BlockingIOError:
                print("retention check already running")
                return 0

            current_size = directory_size(args.media_dir)
            print(
                f"retention check usage={format_bytes(current_size)} "
                f"maximum={format_bytes(args.max_bytes)} "
                f"target={format_bytes(args.target_bytes)}"
            )
            if current_size <= args.max_bytes:
                return 0

            token = load_token(args.token_file)
            client = TubeArchivistClient(
                args.base_url, token, timeout_seconds=args.timeout_seconds
            )
            result = enforce_retention(
                media_dir=args.media_dir,
                max_bytes=args.max_bytes,
                target_bytes=args.target_bytes,
                client=client,
                dry_run=args.dry_run,
                current_size=current_size,
            )
            print(
                f"retention complete deleted={len(result.deleted_ids)} "
                f"before={format_bytes(result.before_bytes)} "
                f"after={format_bytes(result.after_bytes)} "
                f"dry_run={str(result.dry_run).lower()}"
            )
            return 0
    except (OSError, RetentionError, ValueError) as exc:
        print(f"retention failed: {exc}", file=sys.stderr)
        return 1


if __name__ == "__main__":
    raise SystemExit(main())
