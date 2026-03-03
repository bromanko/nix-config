"""
secret-proxy: HTTP proxy that injects secrets into requests.

The client signals which secrets it needs via placeholders in headers
or query parameters:

    # Default namespace (shared secrets) — header
    curl https://api.anthropic.com/v1/messages \
      -H "x-api-key: {{ANTHROPIC_API_KEY}}"

    # Namespaced secrets (per-project 1Password Environments)
    curl https://api.anthropic.com/v1/messages \
      -H "x-api-key: {{michael:ANTHROPIC_API_KEY}}"

    # Query parameter credential
    curl "https://maps.googleapis.com/maps/api/geocode/json?key={{GOOGLE_MAPS_KEY}}"

The proxy:
1. Scans headers and query parameters for {{PLACEHOLDER}} or {{namespace:PLACEHOLDER}} patterns
2. Loads the appropriate env file (default or namespaced)
3. Validates the destination host is allowed for that secret
4. Replaces placeholders with values from 1Password Environment .env file
5. Logs all secret-injected requests for audit purposes
6. (Optional) Redirects LLM API traffic through Context Lens for
   context window visualization

Security features:
- Destination allowlisting via _HOSTS companion variables
- Generic error messages to clients (details only in host logs)
- Structured audit logging
- Per-namespace secret isolation

Usage:
    mitmdump -s secret_proxy.py \
      --set secret_proxy_env_file=~/.config/secret-proxy/secrets.env \
      --set secret_proxy_namespace_dir=~/.config/secret-proxy/namespaces

    # With Context Lens integration:
    mitmdump -s secret_proxy.py \
      --set secret_proxy_env_file=~/.config/secret-proxy/secrets.env \
      --set secret_proxy_namespace_dir=~/.config/secret-proxy/namespaces \
      --set context_lens_enabled=true \
      --set context_lens_port=4040
"""

import http.client
import json
import re
import time
from datetime import datetime, timezone
from pathlib import Path
from typing import Optional

from mitmproxy import ctx, http as mhttp
from mitmproxy.addonmanager import Loader


# LLM API hosts and their Context Lens path prefixes.
# Context Lens uses these prefixes to identify the provider and route
# to the correct upstream.
CONTEXT_LENS_HOSTS: dict[str, str] = {
    "api.anthropic.com": "claude",
    "api.openai.com": "openai",
    "chatgpt.com": "codex",
    "generativelanguage.googleapis.com": "gemini",
    "cloudcode-pa.googleapis.com": "gemini",
    "us-central1-aiplatform.googleapis.com": "vertex",
}


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
    Scans HTTP request headers and query parameters for {{PLACEHOLDER}} or
    {{namespace:PLACEHOLDER}} patterns and replaces them with secrets from
    1Password Environment .env files.

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

        # Context Lens integration
        self.context_lens_enabled: bool = False
        self.context_lens_port: int = 4040
        self._context_lens_alive: bool = False
        self._context_lens_last_check: float = 0
        # Re-check liveness every 30 seconds
        self._context_lens_check_interval: float = 30.0

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
        loader.add_option(
            name="context_lens_enabled",
            typespec=bool,
            default=False,
            help="Redirect LLM API traffic through Context Lens for visualization",
        )
        loader.add_option(
            name="context_lens_port",
            typespec=int,
            default=4040,
            help="Port where Context Lens proxy is listening",
        )

    def configure(self, updated: set[str]):
        if "secret_proxy_env_file" in updated and ctx.options.secret_proxy_env_file:
            self.env_file_path = Path(ctx.options.secret_proxy_env_file).expanduser()
            ctx.log.info(f"secret-proxy: Default secrets from {self.env_file_path}")

        if "secret_proxy_namespace_dir" in updated and ctx.options.secret_proxy_namespace_dir:
            self.namespace_dir = Path(ctx.options.secret_proxy_namespace_dir).expanduser()
            ctx.log.info(f"secret-proxy: Namespace directory: {self.namespace_dir}")

        if "context_lens_enabled" in updated:
            self.context_lens_enabled = ctx.options.context_lens_enabled
            if self.context_lens_enabled:
                ctx.log.info("secret-proxy: Context Lens integration enabled")
            else:
                ctx.log.info("secret-proxy: Context Lens integration disabled")

        if "context_lens_port" in updated:
            self.context_lens_port = ctx.options.context_lens_port

    def _is_context_lens_alive(self) -> bool:
        """
        Check if Context Lens is running, with caching to avoid per-request overhead.

        Returns True if Context Lens responded to a TCP connection within the
        last check interval, False otherwise.
        """
        now = time.monotonic()
        if now - self._context_lens_last_check < self._context_lens_check_interval:
            return self._context_lens_alive

        self._context_lens_last_check = now
        try:
            conn = http.client.HTTPConnection(
                "127.0.0.1", self.context_lens_port, timeout=1
            )
            conn.request("HEAD", "/")
            conn.getresponse()
            conn.close()
            if not self._context_lens_alive:
                ctx.log.info(
                    f"secret-proxy: Context Lens is available on port {self.context_lens_port}"
                )
            self._context_lens_alive = True
        except Exception:
            if self._context_lens_alive:
                ctx.log.warn(
                    f"secret-proxy: Context Lens not responding on port {self.context_lens_port}, "
                    "forwarding directly to APIs"
                )
            self._context_lens_alive = False

        return self._context_lens_alive

    def _redirect_through_context_lens(self, flow: mhttp.HTTPFlow) -> None:
        """
        Redirect an LLM API request through Context Lens.

        Modifies the flow's destination to point at the local Context Lens
        proxy, preserving the original URL in an x-target-url header so
        Context Lens knows where to forward.
        """
        original_host = flow.request.host.lower()
        prefix = CONTEXT_LENS_HOSTS.get(original_host)
        if prefix is None:
            return

        if not self._is_context_lens_alive():
            return

        # Save the original URL so Context Lens can forward to the real API
        original_url = flow.request.url
        flow.request.headers["x-target-url"] = original_url

        # Redirect to Context Lens
        flow.request.scheme = "http"
        flow.request.host = "127.0.0.1"
        flow.request.port = self.context_lens_port
        flow.request.path = f"/{prefix}{flow.request.path}"

        ctx.log.debug(
            f"secret-proxy: Redirecting {original_host} through Context Lens: "
            f"{original_url} → http://127.0.0.1:{self.context_lens_port}/{prefix}/..."
        )

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
        flow: mhttp.HTTPFlow,
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

    def _block_request(self, flow: mhttp.HTTPFlow, secrets_involved: list[str], reason: str):
        """
        Block a request with a generic error message.

        The specific reason is logged on the host but not returned to the client.
        """
        self._log_audit(flow, secrets_involved, blocked=True, block_reason=reason)

        flow.response = mhttp.Response.make(
            403,
            GENERIC_ERROR_MESSAGE.encode(),
            {"Content-Type": "text/plain; charset=utf-8"},
        )

    def request(self, flow: mhttp.HTTPFlow):
        """Process each request, replacing placeholders and optionally redirecting to Context Lens."""

        # First pass: find all placeholders in headers and query parameters
        all_placeholders = []
        for header_name in flow.request.headers.keys():
            header_value = flow.request.headers[header_name]
            placeholders = self._find_placeholders(header_value)
            all_placeholders.extend(placeholders)

        for _, query_value in flow.request.query.fields:
            placeholders = self._find_placeholders(query_value)
            all_placeholders.extend(placeholders)

        # If placeholders are present, validate and replace them
        if all_placeholders:
            self._inject_secrets(flow, all_placeholders)
            # If the request was blocked, don't redirect
            if flow.response:
                return

        # Redirect LLM API traffic through Context Lens for visualization.
        # This applies to ALL LLM API requests — both placeholder-injected
        # and OAuth/token-authenticated — so every tool is captured.
        if self.context_lens_enabled:
            self._redirect_through_context_lens(flow)

    def _inject_secrets(self, flow: mhttp.HTTPFlow, all_placeholders: list[str]) -> None:
        """Validate and replace {{PLACEHOLDER}} patterns in request headers and query parameters."""

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

        def replacer(match: re.Match) -> str:
            full = match.group(1)
            namespace, key = parse_placeholder(full)
            secrets, _ = namespace_data[namespace]
            if key in secrets:
                all_replaced.append(full)
                return secrets[key]
            return match.group(0)

        # Replace in headers
        for header_name in list(flow.request.headers.keys()):
            header_value = flow.request.headers[header_name]

            placeholders = self._find_placeholders(header_value)
            if not placeholders:
                continue

            new_value = PLACEHOLDER_PATTERN.sub(replacer, header_value)
            if new_value != header_value:
                flow.request.headers[header_name] = new_value

        # Replace in query parameters
        new_query_fields = []
        query_changed = False
        for qname, qvalue in flow.request.query.fields:
            placeholders = self._find_placeholders(qvalue)
            if placeholders:
                new_value = PLACEHOLDER_PATTERN.sub(replacer, qvalue)
                if new_value != qvalue:
                    query_changed = True
                new_query_fields.append((qname, new_value))
            else:
                new_query_fields.append((qname, qvalue))

        if query_changed:
            flow.request.query = new_query_fields

        # Log successful injection
        if all_replaced:
            self._log_audit(flow, list(set(all_replaced)), blocked=False)


addons = [SecretProxy()]
