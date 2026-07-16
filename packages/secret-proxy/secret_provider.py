"""Secret sources for secret-proxy.

Providers return parsed 1Password Environment variables without exposing values to
callers outside the proxy process. The legacy provider reads 1Password's local FIFO
mounts with a bounded subprocess. The headless provider invokes 1Password CLI with a
service-account token supplied only in the child process environment.
"""

from __future__ import annotations

import os
import subprocess
import time
from pathlib import Path
from typing import Callable, Optional


class SecretProviderError(RuntimeError):
    """A provider failed without including secret-bearing command output."""


def parse_env_content(content: str) -> dict[str, str]:
    """Parse KEY=VALUE lines from 1Password Environment output."""
    env_vars: dict[str, str] = {}

    for raw_line in content.splitlines():
        line = raw_line.strip()
        if not line or line.startswith("#") or "=" not in line:
            continue

        key, _, value = line.partition("=")
        key = key.strip()
        value = value.strip()

        if len(value) >= 2 and (
            (value[0] == '"' and value[-1] == '"')
            or (value[0] == "'" and value[-1] == "'")
        ):
            value = value[1:-1]

        if key:
            env_vars[key] = value

    return env_vars


class EnvironmentFileProvider:
    """Read default and namespaced 1Password local Environment FIFOs."""

    def __init__(
        self,
        default_env_file: Path,
        namespace_dir: Path,
        read_timeout_seconds: float = 15,
        runner: Callable = subprocess.run,
    ) -> None:
        self.default_env_file = default_env_file
        self.namespace_dir = namespace_dir
        self.read_timeout_seconds = read_timeout_seconds
        self._runner = runner

    def _path_for_namespace(self, namespace: Optional[str]) -> Path:
        if namespace is None:
            return self.default_env_file
        return self.namespace_dir / namespace / "secrets.env"

    def load(self, namespace: Optional[str]) -> dict[str, str]:
        path = self._path_for_namespace(namespace)

        try:
            result = self._runner(
                ["/bin/cat", str(path)],
                check=False,
                capture_output=True,
                text=True,
                timeout=self.read_timeout_seconds,
            )
        except subprocess.TimeoutExpired as error:
            raise SecretProviderError("Environment file read timed out") from error
        except OSError as error:
            raise SecretProviderError("Environment file read failed") from error

        if result.returncode != 0:
            raise SecretProviderError("Environment file read failed")

        return parse_env_content(result.stdout)


class OnePasswordServiceAccountProvider:
    """Read 1Password Environments headlessly through a scoped service account."""

    def __init__(
        self,
        op_cli: str,
        token_file: Path,
        environment_ids: dict[str, str],
        cache_ttl_seconds: float = 300,
        command_timeout_seconds: float = 15,
        runner: Callable = subprocess.run,
        clock: Callable[[], float] = time.monotonic,
        base_environment: Optional[dict[str, str]] = None,
    ) -> None:
        self.op_cli = op_cli
        self.token_file = token_file
        self.environment_ids = dict(environment_ids)
        self.cache_ttl_seconds = cache_ttl_seconds
        self.command_timeout_seconds = command_timeout_seconds
        self._runner = runner
        self._clock = clock
        self._base_environment = (
            dict(base_environment) if base_environment is not None else os.environ.copy()
        )
        self._cache: dict[Optional[str], tuple[dict[str, str], float]] = {}

    def _environment_id(self, namespace: Optional[str]) -> str:
        label = "default" if namespace is None else namespace
        environment_id = self.environment_ids.get(label, "").strip()
        if not environment_id:
            raise SecretProviderError(
                f"No Environment ID configured for namespace '{label}'"
            )
        return environment_id

    def _service_account_token(self) -> str:
        try:
            token = self.token_file.read_text().strip()
        except OSError as error:
            raise SecretProviderError("Service account token file is unavailable") from error

        if not token:
            raise SecretProviderError("Service account token file is empty")
        return token

    def _cached(self, namespace: Optional[str]) -> Optional[dict[str, str]]:
        entry = self._cache.get(namespace)
        if entry is None:
            return None

        variables, expires_at = entry
        if self._clock() >= expires_at:
            del self._cache[namespace]
            return None
        return dict(variables)

    def load(self, namespace: Optional[str]) -> dict[str, str]:
        cached = self._cached(namespace)
        if cached is not None:
            return cached

        environment_id = self._environment_id(namespace)
        token = self._service_account_token()
        child_environment = dict(self._base_environment)
        child_environment.pop("OP_CONNECT_HOST", None)
        child_environment.pop("OP_CONNECT_TOKEN", None)
        child_environment["OP_SERVICE_ACCOUNT_TOKEN"] = token

        command = [self.op_cli, "environment", "read", environment_id]
        try:
            result = self._runner(
                command,
                check=False,
                capture_output=True,
                text=True,
                timeout=self.command_timeout_seconds,
                env=child_environment,
            )
        except subprocess.TimeoutExpired as error:
            raise SecretProviderError("1Password Environment read timed out") from error
        except OSError as error:
            raise SecretProviderError("1Password Environment read failed") from error

        if result.returncode != 0:
            raise SecretProviderError("1Password Environment read failed")

        variables = parse_env_content(result.stdout)
        if self.cache_ttl_seconds > 0:
            self._cache[namespace] = (
                dict(variables),
                self._clock() + self.cache_ttl_seconds,
            )
        return variables
