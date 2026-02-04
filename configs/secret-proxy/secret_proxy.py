"""
secret-proxy: HTTP proxy that injects secrets into requests.

The client signals which secrets it needs via placeholders in headers:

    curl https://api.anthropic.com/v1/messages \
      -H "x-api-key: {{ANTHROPIC_API_KEY}}"

The proxy:
1. Scans headers for {{PLACEHOLDER}} patterns
2. Validates the destination host is allowed for that secret
3. Replaces placeholders with values from 1Password Environment .env file
4. Logs all secret-injected requests for audit purposes

Security features:
- Destination allowlisting via _HOSTS companion variables
- Generic error messages to clients (details only in host logs)
- Structured audit logging

Usage:
    mitmdump -s secret_proxy.py --set secret_proxy_env_file=~/.config/secret-proxy/secrets.env
"""

import json
import re
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from mitmproxy import ctx, http
from mitmproxy.addonmanager import Loader


# Pattern matches {{VARIABLE_NAME}}
PLACEHOLDER_PATTERN = re.compile(r'\{\{([A-Za-z_][A-Za-z0-9_]*)\}\}')

# Generic error message returned to clients (no information leakage)
GENERIC_ERROR_MESSAGE = """403 Forbidden

Request blocked by secret-proxy policy.

If you believe this is an error, check the proxy logs on the host.
"""


class SecretProxy:
    """
    Scans HTTP request headers for {{PLACEHOLDER}} patterns and replaces
    them with secrets from a 1Password Environment mounted .env file.

    Security model:
    - Each secret must have a corresponding _HOSTS variable defining allowed destinations
    - Requests to non-allowed hosts are blocked
    - Error messages are generic to prevent information leakage
    - All secret usage is logged for audit purposes
    """

    def __init__(self):
        self.env_file_path: Optional[Path] = None

    def load(self, loader: Loader):
        loader.add_option(
            name="secret_proxy_env_file",
            typespec=str,
            default="",
            help="Path to 1Password Environment mounted .env file",
        )

    def configure(self, updated: set[str]):
        if "secret_proxy_env_file" in updated and ctx.options.secret_proxy_env_file:
            self.env_file_path = Path(ctx.options.secret_proxy_env_file).expanduser()
            ctx.log.info(f"secret-proxy: Using secrets from {self.env_file_path}")

    def _load_env_file(self) -> dict[str, str]:
        """
        Load all variables from the .env file.

        For 1Password Environments, this is a UNIX named pipe that returns
        secrets on read. We read fresh each time to pick up changes.

        Returns a dict of all KEY=VALUE pairs (both secrets and _HOSTS variables).
        """
        if not self.env_file_path:
            return {}

        if not self.env_file_path.exists():
            ctx.log.warn(f"secret-proxy: Env file not found: {self.env_file_path}")
            return {}

        env_vars = {}

        try:
            with open(self.env_file_path) as f:
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
            ctx.log.error(f"secret-proxy: Failed to load env file: {e}")
            return {}

    def _parse_secrets_and_hosts(self, env_vars: dict[str, str]) -> tuple[dict[str, str], dict[str, set[str]]]:
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

    def _find_placeholders(self, value: str) -> list[str]:
        """Extract all {{PLACEHOLDER}} names from a string."""
        return PLACEHOLDER_PATTERN.findall(value)

    def _replace_placeholders(self, value: str, secrets: dict[str, str]) -> tuple[str, list[str], list[str]]:
        """
        Replace {{PLACEHOLDER}} patterns with secret values.

        Returns (new_value, list_of_replaced_keys, list_of_missing_keys).
        """
        missing = []
        replaced = []

        def replacer(match):
            key = match.group(1)
            if key in secrets:
                replaced.append(key)
                return secrets[key]
            else:
                missing.append(key)
                return match.group(0)  # Leave unchanged

        new_value = PLACEHOLDER_PATTERN.sub(replacer, value)
        return new_value, replaced, missing

    def _log_audit(self, flow: http.HTTPFlow, secrets_used: list[str], blocked: bool, block_reason: Optional[str] = None):
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
        # Log the specific reason (visible only on host)
        self._log_audit(flow, secrets_involved, blocked=True, block_reason=reason)

        # Return generic error to client (no information leakage)
        flow.response = http.Response.make(
            403,
            GENERIC_ERROR_MESSAGE.encode(),
            {"Content-Type": "text/plain; charset=utf-8"}
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

        # Load secrets and allowed hosts
        env_vars = self._load_env_file()
        secrets, allowed_hosts = self._parse_secrets_and_hosts(env_vars)

        request_host = flow.request.host.lower()

        # Validate each placeholder
        for placeholder in unique_placeholders:
            # Check if secret exists
            if placeholder not in secrets:
                self._block_request(
                    flow,
                    unique_placeholders,
                    f"Secret not found: {placeholder}"
                )
                return

            # Check if _HOSTS is defined for this secret
            if placeholder not in allowed_hosts:
                self._block_request(
                    flow,
                    unique_placeholders,
                    f"No allowed hosts defined for: {placeholder} (missing {placeholder}_HOSTS)"
                )
                return

            # Check if request host is in the allowed list
            if request_host not in allowed_hosts[placeholder]:
                self._block_request(
                    flow,
                    unique_placeholders,
                    f"Host '{request_host}' not allowed for {placeholder} (allowed: {allowed_hosts[placeholder]})"
                )
                return

        # All validations passed - replace placeholders
        all_replaced = []

        for header_name in list(flow.request.headers.keys()):
            header_value = flow.request.headers[header_name]

            placeholders = self._find_placeholders(header_value)
            if not placeholders:
                continue

            new_value, replaced, missing = self._replace_placeholders(header_value, secrets)
            all_replaced.extend(replaced)

            if new_value != header_value:
                flow.request.headers[header_name] = new_value

        # Log successful injection
        if all_replaced:
            self._log_audit(flow, list(set(all_replaced)), blocked=False)


addons = [SecretProxy()]
