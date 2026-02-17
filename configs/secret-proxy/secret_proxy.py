"""
secret-proxy: HTTP proxy that injects secrets into requests.

The client signals which secrets it needs via placeholders in headers:

    # Default namespace (shared secrets)
    curl https://api.anthropic.com/v1/messages \
      -H "x-api-key: {{ANTHROPIC_API_KEY}}"

    # Namespaced secrets (per-project 1Password Environments)
    curl https://api.anthropic.com/v1/messages \
      -H "x-api-key: {{michael:ANTHROPIC_API_KEY}}"

The proxy:
1. Scans headers for {{PLACEHOLDER}} or {{namespace:PLACEHOLDER}} patterns
2. Loads the appropriate env file (default or namespaced)
3. Validates the destination host is allowed for that secret
4. Replaces placeholders with values from 1Password Environment .env file
5. Logs all secret-injected requests for audit purposes

Security features:
- Destination allowlisting via _HOSTS companion variables
- Generic error messages to clients (details only in host logs)
- Structured audit logging
- Per-namespace secret isolation

Usage:
    mitmdump -s secret_proxy.py \
      --set secret_proxy_env_file=~/.config/secret-proxy/secrets.env \
      --set secret_proxy_namespace_dir=~/.config/secret-proxy/namespaces
"""

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from mitmproxy import ctx, http
from mitmproxy.addonmanager import Loader


# Pattern matches {{VARIABLE_NAME}} or {{namespace:VARIABLE_NAME}}
# Group 1: full match content (e.g. "michael:API_KEY" or "API_KEY")
# We parse namespace vs key after matching.
PLACEHOLDER_PATTERN = re.compile(
    r'\{\{((?:[A-Za-z_][A-Za-z0-9_]*:)?[A-Za-z_][A-Za-z0-9_]*)\}\}'
)

# Generic error message returned to clients (no information leakage)
GENERIC_ERROR_MESSAGE = """403 Forbidden

Request blocked by secret-proxy policy.

If you believe this is an error, check the proxy logs on the host.
"""


def parse_placeholder(placeholder: str) -> tuple[Optional[str], str]:
    """
    Parse a placeholder into (namespace, key).

    "API_KEY"           -> (None, "API_KEY")
    "michael:API_KEY"   -> ("michael", "API_KEY")
    """
    if ':' in placeholder:
        namespace, _, key = placeholder.partition(':')
        return namespace, key
    return None, placeholder


def load_env_from_path(path: Path) -> dict[str, str]:
    """
    Load all variables from a .env file.

    For 1Password Environments, this is a UNIX named pipe that returns
    secrets on read. We read fresh each time to pick up changes.

    Returns a dict of all KEY=VALUE pairs (both secrets and _HOSTS variables).
    """
    if not path.exists():
        ctx.log.warn(f"secret-proxy: Env file not found: {path}")
        return {}

    env_vars = {}

    try:
        with open(path) as f:
            content = f.read()

        for line in content.splitlines():
            line = line.strip()

            # Skip comments and empty lines
            if not line or line.startswith('#'):
                continue

            # Parse KEY=VALUE
            if '=' not in line:
                continue

            key, _, value = line.partition('=')
            key = key.strip()
            value = value.strip()

            # Remove surrounding quotes if present
            if len(value) >= 2:
                if (value[0] == '"' and value[-1] == '"') or \
                   (value[0] == "'" and value[-1] == "'"):
                    value = value[1:-1]

            if key:
                env_vars[key] = value

        return env_vars

    except Exception as e:
        ctx.log.error(f"secret-proxy: Failed to load env file {path}: {e}")
        return {}


def parse_secrets_and_hosts(
    env_vars: dict[str, str],
) -> tuple[dict[str, str], dict[str, set[str]]]:
    """
    Separate env vars into secrets and their allowed hosts.

    Variables ending in _HOSTS are parsed as comma-separated host lists.
    All other variables are treated as secrets.

    Returns (secrets, allowed_hosts) where:
    - secrets: {"ANTHROPIC_API_KEY": "sk-ant-..."}
    - allowed_hosts: {"ANTHROPIC_API_KEY": {"api.anthropic.com"}}
    """
    secrets = {}
    allowed_hosts = {}

    for key, value in env_vars.items():
        if key.endswith("_HOSTS"):
            # This is a host allowlist
            secret_name = key[:-6]  # Remove _HOSTS suffix
            hosts = {h.strip().lower() for h in value.split(",") if h.strip()}
            allowed_hosts[secret_name] = hosts
        else:
            secrets[key] = value

    return secrets, allowed_hosts


class SecretProxy:
    """
    Scans HTTP request headers for {{PLACEHOLDER}} or {{namespace:PLACEHOLDER}}
    patterns and replaces them with secrets from 1Password Environment .env files.

    Namespacing allows separate 1Password Environments per project. Each
    namespace has its own env file under the namespace directory. Placeholders
    without a namespace use the default env file.

    Security model:
    - Each secret must have a corresponding _HOSTS variable defining allowed destinations
    - Requests to non-allowed hosts are blocked
    - Error messages are generic to prevent information leakage
    - All secret usage is logged for audit purposes
    - Namespaces are fully isolated from each other
    """

    def __init__(self):
        self.env_file_path: Optional[Path] = None
        self.namespace_dir: Optional[Path] = None

    def load(self, loader: Loader):
        loader.add_option(
            name="secret_proxy_env_file",
            typespec=str,
            default="",
            help="Path to default 1Password Environment mounted .env file",
        )
        loader.add_option(
            name="secret_proxy_namespace_dir",
            typespec=str,
            default="",
            help="Directory containing per-namespace env files (each in <name>/secrets.env)",
        )

    def configure(self, updated: set[str]):
        if "secret_proxy_env_file" in updated and ctx.options.secret_proxy_env_file:
            self.env_file_path = Path(ctx.options.secret_proxy_env_file).expanduser()
            ctx.log.info(f"secret-proxy: Default secrets from {self.env_file_path}")

        if "secret_proxy_namespace_dir" in updated and ctx.options.secret_proxy_namespace_dir:
            self.namespace_dir = Path(ctx.options.secret_proxy_namespace_dir).expanduser()
            ctx.log.info(f"secret-proxy: Namespace directory: {self.namespace_dir}")

    def _env_file_for_namespace(self, namespace: Optional[str]) -> Optional[Path]:
        """
        Return the env file path for a given namespace.

        None namespace -> default env file
        Named namespace -> <namespace_dir>/<namespace>/secrets.env
        """
        if namespace is None:
            return self.env_file_path

        if not self.namespace_dir:
            return None

        return self.namespace_dir / namespace / "secrets.env"

    def _load_namespace(self, namespace: Optional[str]) -> tuple[dict[str, str], dict[str, set[str]]]:
        """
        Load and parse secrets + hosts for a given namespace.

        Returns (secrets, allowed_hosts) or empty dicts if the env file
        doesn't exist.
        """
        path = self._env_file_for_namespace(namespace)
        if path is None:
            return {}, {}

        env_vars = load_env_from_path(path)
        return parse_secrets_and_hosts(env_vars)

    def _find_placeholders(self, value: str) -> list[str]:
        """Extract all {{PLACEHOLDER}} or {{ns:PLACEHOLDER}} strings from a value."""
        return PLACEHOLDER_PATTERN.findall(value)

    def _log_audit(
        self,
        flow: http.HTTPFlow,
        secrets_used: list[str],
        blocked: bool,
        block_reason: Optional[str] = None,
    ):
        """
        Log structured audit entry for requests involving secrets.

        These logs are written to the host and are not visible to the VM.
        """
        entry = {
            "timestamp": datetime.now(timezone.utc).isoformat(),
            "secrets": secrets_used,
            "method": flow.request.method,
            "host": flow.request.host,
            "path": flow.request.path,
            "blocked": blocked,
        }
        if block_reason:
            entry["reason"] = block_reason

        ctx.log.info(f"secret-proxy-audit: {json.dumps(entry)}")

    def _block_request(self, flow: http.HTTPFlow, secrets_involved: list[str], reason: str):
        """
        Block a request with a generic error message.

        The specific reason is logged on the host but not returned to the client.
        """
        self._log_audit(flow, secrets_involved, blocked=True, block_reason=reason)

        flow.response = http.Response.make(
            403,
            GENERIC_ERROR_MESSAGE.encode(),
            {"Content-Type": "text/plain; charset=utf-8"},
        )

    def request(self, flow: http.HTTPFlow):
        """Process each request, validating hosts and replacing placeholders in headers."""

        # First pass: find all placeholders in all headers
        all_placeholders = []
        for header_name in flow.request.headers.keys():
            header_value = flow.request.headers[header_name]
            placeholders = self._find_placeholders(header_value)
            all_placeholders.extend(placeholders)

        # If no placeholders, let request through unchanged
        if not all_placeholders:
            return

        unique_placeholders = list(set(all_placeholders))
        request_host = flow.request.host.lower()

        # Group placeholders by namespace so we load each env file at most once
        # Key: namespace (None for default), Value: list of secret keys
        by_namespace: dict[Optional[str], list[str]] = {}
        for placeholder in unique_placeholders:
            namespace, key = parse_placeholder(placeholder)
            by_namespace.setdefault(namespace, []).append(key)

        # Load and cache secrets per namespace
        namespace_data: dict[Optional[str], tuple[dict[str, str], dict[str, set[str]]]] = {}
        for namespace in by_namespace:
            namespace_data[namespace] = self._load_namespace(namespace)

        # Validate each placeholder
        for placeholder in unique_placeholders:
            namespace, key = parse_placeholder(placeholder)
            ns_label = f"{namespace}:" if namespace else ""
            secrets, allowed_hosts = namespace_data[namespace]

            # Check if the namespace env file was loadable
            env_path = self._env_file_for_namespace(namespace)
            if env_path is None:
                self._block_request(
                    flow,
                    unique_placeholders,
                    f"Namespace not configured: {namespace}"
                    if namespace
                    else "Default env file not configured",
                )
                return

            # Check if secret exists
            if key not in secrets:
                self._block_request(
                    flow,
                    unique_placeholders,
                    f"Secret not found: {ns_label}{key}",
                )
                return

            # Check if _HOSTS is defined for this secret
            if key not in allowed_hosts:
                self._block_request(
                    flow,
                    unique_placeholders,
                    f"No allowed hosts defined for: {ns_label}{key} (missing {key}_HOSTS)",
                )
                return

            # Check if request host is in the allowed list
            if request_host not in allowed_hosts[key]:
                self._block_request(
                    flow,
                    unique_placeholders,
                    f"Host '{request_host}' not allowed for {ns_label}{key} "
                    f"(allowed: {allowed_hosts[key]})",
                )
                return

        # All validations passed — replace placeholders
        all_replaced = []

        for header_name in list(flow.request.headers.keys()):
            header_value = flow.request.headers[header_name]

            placeholders = self._find_placeholders(header_value)
            if not placeholders:
                continue

            def replacer(match: re.Match) -> str:
                full = match.group(1)
                namespace, key = parse_placeholder(full)
                secrets, _ = namespace_data[namespace]
                if key in secrets:
                    all_replaced.append(full)
                    return secrets[key]
                return match.group(0)

            new_value = PLACEHOLDER_PATTERN.sub(replacer, header_value)
            if new_value != header_value:
                flow.request.headers[header_name] = new_value

        # Log successful injection
        if all_replaced:
            self._log_audit(flow, list(set(all_replaced)), blocked=False)


addons = [SecretProxy()]
