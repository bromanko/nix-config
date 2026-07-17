import os
from pathlib import Path
import tempfile
import unittest

import retention


GIB = 1024**3


class FakeClient:
    def __init__(self, videos, failure_id=None):
        self.videos = videos
        self.failure_id = failure_id
        self.list_calls = 0
        self.deleted = []

    def list_videos(self):
        self.list_calls += 1
        return list(self.videos)

    def delete_video(self, youtube_id):
        if youtube_id == self.failure_id:
            raise retention.RetentionError("synthetic delete failure")
        self.deleted.append(youtube_id)


class RetentionTests(unittest.TestCase):
    def video(self, youtube_id, size, published, watched=False):
        return retention.Video(youtube_id, youtube_id, published, size, watched)

    def test_directory_size_counts_files_and_ignores_symlinks(self):
        with tempfile.TemporaryDirectory() as tmp:
            root = Path(tmp)
            (root / "channel").mkdir()
            (root / "channel" / "video.mp4").write_bytes(b"a" * 11)
            (root / "subtitle.vtt").write_bytes(b"b" * 7)
            os.symlink(root / "channel" / "video.mp4", root / "duplicate")

            self.assertEqual(retention.directory_size(root), 18)

    def test_below_limit_does_not_query_api(self):
        client = FakeClient([])
        result = retention.enforce_retention(
            media_dir=Path("/unused"),
            max_bytes=200 * GIB,
            target_bytes=180 * GIB,
            client=client,
            current_size=17 * GIB,
        )

        self.assertFalse(result.over_limit)
        self.assertEqual(result.deleted_ids, ())
        self.assertEqual(client.list_calls, 0)

    def test_watched_videos_are_deleted_before_older_unwatched_videos(self):
        videos = [
            self.video("old-unwatched", 30 * GIB, "2020-01-01"),
            self.video("new-watched", 20 * GIB, "2025-01-01", watched=True),
            self.video("new-unwatched", 40 * GIB, "2026-01-01"),
        ]
        client = FakeClient(videos)
        result = retention.enforce_retention(
            media_dir=Path("/unused"),
            max_bytes=200 * GIB,
            target_bytes=180 * GIB,
            client=client,
            current_size=230 * GIB,
            size_reader=lambda _: 180 * GIB,
        )

        self.assertEqual(client.deleted, ["new-watched", "old-unwatched"])
        self.assertEqual(result.deleted_ids, tuple(client.deleted))
        self.assertEqual(result.after_bytes, 180 * GIB)

    def test_oldest_publication_is_deleted_first_within_watch_group(self):
        videos = [
            self.video("new", 30 * GIB, "2025-01-01"),
            self.video("old", 30 * GIB, "2020-01-01"),
        ]
        client = FakeClient(videos)
        retention.enforce_retention(
            media_dir=Path("/unused"),
            max_bytes=200 * GIB,
            target_bytes=180 * GIB,
            client=client,
            current_size=210 * GIB,
            size_reader=lambda _: 180 * GIB,
        )

        self.assertEqual(client.deleted, ["old"])

    def test_dry_run_reports_deletions_without_calling_delete(self):
        videos = [self.video("old", 30 * GIB, "2020-01-01")]
        client = FakeClient(videos)
        result = retention.enforce_retention(
            media_dir=Path("/unused"),
            max_bytes=200 * GIB,
            target_bytes=180 * GIB,
            client=client,
            dry_run=True,
            current_size=210 * GIB,
        )

        self.assertEqual(client.deleted, [])
        self.assertEqual(result.deleted_ids, ("old",))
        self.assertEqual(result.after_bytes, 180 * GIB)

    def test_delete_failure_stops_cleanup(self):
        videos = [self.video("old", 30 * GIB, "2020-01-01")]
        client = FakeClient(videos, failure_id="old")

        with self.assertRaisesRegex(retention.RetentionError, "synthetic"):
            retention.enforce_retention(
                media_dir=Path("/unused"),
                max_bytes=200 * GIB,
                target_bytes=180 * GIB,
                client=client,
                current_size=210 * GIB,
            )

    def test_cleanup_fails_when_indexed_media_cannot_reach_target(self):
        client = FakeClient([self.video("small", 5 * GIB, "2020-01-01")])

        with self.assertRaisesRegex(retention.RetentionError, "enough indexed media"):
            retention.enforce_retention(
                media_dir=Path("/unused"),
                max_bytes=200 * GIB,
                target_bytes=180 * GIB,
                client=client,
                current_size=210 * GIB,
            )

    def test_target_must_be_below_maximum(self):
        with self.assertRaisesRegex(retention.RetentionError, "below maximum"):
            retention.enforce_retention(
                media_dir=Path("/unused"),
                max_bytes=200,
                target_bytes=200,
                client=FakeClient([]),
                current_size=0,
            )

    def test_list_videos_paginates_deduplicates_and_skips_invalid_items(self):
        class PagingClient(retention.TubeArchivistClient):
            def __init__(self):
                self.pages = []

            def _video_page(self, page=None):
                self.pages.append(page)
                values = {
                    None: {
                        "data": [
                            {
                                "youtube_id": "first",
                                "title": "First",
                                "published": "2020",
                                "media_size": 10,
                                "player": {"watched": True},
                            },
                            {"youtube_id": "invalid", "media_size": 0},
                        ],
                        "paginate": {"last_page": 3},
                    },
                    2: {
                        "data": [
                            {
                                "youtube_id": "second",
                                "published": "2021",
                                "media_size": 20,
                                "player": {"watched": False},
                            }
                        ]
                    },
                    3: {
                        "data": [
                            {
                                "youtube_id": "first",
                                "published": "2020",
                                "media_size": 10,
                            }
                        ]
                    },
                }
                return values[page]

        client = PagingClient()
        videos = client.list_videos()

        self.assertEqual(client.pages, [None, 2, 3])
        self.assertEqual([video.youtube_id for video in videos], ["first", "second"])
        self.assertTrue(videos[0].watched)


if __name__ == "__main__":
    unittest.main()
