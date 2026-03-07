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

    # Derived secret (generated on the fly from component secrets)
    curl https://api.music.apple.com/v1/catalog/us/songs/203709340 \
      -H "Authorization: Bearer {{APPLE_MUSIC_TOKEN}}"

The proxy:
1. Scans headers and query parameters for {{PLACEHOLDER}} or {{namespace:PLACEHOLDER}} patterns
2. Loads the appropriate env file (default or namespaced)
3. Validates the destination host is allowed for that secret
4. Resolves the secret value — either directly from the env file or by
   calling a registered generator for derived secrets
5. Replaces placeholders with resolved values
6. Logs all secret-injected requests for audit purposes
7. (Optional) Redirects LLM API traffic through Context Lens for
   context window visualization

Security features:
- Destination allowlisting via _HOSTS companion variables
- Derived secret generators (e.g., ES256 JWTs) with TTL-based caching
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
from typing import Callable, Optional

from mitmproxy import ctx, http as mhttp
from mitmproxy.addonmanager import Loader

# PyJWT is optional — only required when using JWT-based generators.
# The import is deferred so the proxy starts even if PyJWT isn't installed;
# generators that need it will fail with a clear message at call time.
try:
    import jwt as pyjwt
except ImportError:
    pyjwt = None


# ── Derived Secret Generators ──────────────────────────────────────────

def _derive_prefix(secret_name: str) -> str:
    """Derive the component secret prefix from a derived secret name.

    Strips a known "output" suffix so component secrets follow a natural
    naming convention:

        APPLE_MUSIC_TOKEN -> APPLE_MUSIC
        MY_API_JWT        -> MY_API
        SOME_CREDENTIAL   -> SOME_CREDENTIAL  (no known suffix, use as-is)
    """
    for suffix in ("_TOKEN", "_JWT"):
        if secret_name.endswith(suffix):
            return secret_name[:-len(suffix)]
    return secret_name


def generate_es256_jwt(secret_name: str, secrets: dict[str, str]) -> str:
    """Generate an ES256-signed JWT from component secrets.

    This is a general-purpose generator for APIs that authenticate via
    ES256 JWTs (e.g., Apple Music, Apple MapKit, some custom services).

    Component secrets are resolved from the same namespace using a prefix
    derived from the secret name (e.g., APPLE_MUSIC_TOKEN → prefix APPLE_MUSIC):

        {PREFIX}_PRIVATE_KEY  — EC P-256 private key in PEM format
        {PREFIX}_KEY_ID       — JWT ``kid`` header value
        {PREFIX}_ISSUER       — JWT ``iss`` claim value
        {PREFIX}_JWT_TTL      — Token lifetime in seconds (optional, default 43200 = 12h)
    """
    if pyjwt is None:
        raise RuntimeError(
            "PyJWT is not installed. Add pyjwt and cryptography to the "
            "mitmproxy Python environment (see secret-proxy README)."
        )

    prefix = _derive_prefix(secret_name)
    private_key = secrets[f"{prefix}_PRIVATE_KEY"]
    key_id = secrets[f"{prefix}_KEY_ID"]
    issuer = secrets[f"{prefix}_ISSUER"]
    ttl = int(secrets.get(f"{prefix}_JWT_TTL", "43200"))

    now = int(time.time())
    payload = {
        "iss": issuer,
        "iat": now,
        "exp": now + ttl,
    }
    return pyjwt.encode(
        payload, private_key, algorithm="ES256", headers={"kid": key_id}
    )


# Registry of available generators.
#
# Each entry maps a generator name (referenced by _GENERATOR env vars)
# to its configuration:
#
#   func:              (secret_name, secrets_dict) -> derived_value_string
#   cache_ttl:         How long to cache the derived value (seconds)
#   required_suffixes: Appended to the derived prefix to get required
#                      component secret names for pre-flight validation
GENERATORS: dict[str, dict] = {
    "es256_jwt": {
        "func": generate_es256_jwt,
        "cache_ttl": 39600,  # 11 hours (default 12h token minus 1h safety margin)
        "required_suffixes": ["_PRIVATE_KEY", "_KEY_ID", "_ISSUER"],
    },
}


class DerivedSecretCache:
    """In-memory TTL cache for derived (generated) secret values.

    Cache keys include the namespace so the same generator in different
    namespaces produces independent entries.
    """

    def __init__(self):
        self._cache: dict[str, tuple[str, float]] = {}  # key -> (value, expires_at)

    def get(self, key: str) -> Optional[str]:
        entry = self._cache.get(key)
        if entry is not None:
            value, expires_at = entry
            if time.monotonic() < expires_at:
                return value
            del self._cache[key]
        return None

    def set(self, key: str, value: str, ttl: float) -> None:
        self._cache[key] = (value, time.monotonic() + ttl)


# ── LLM API / Context Lens ────────────────────────────────────────────

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


# ── Placeholder parsing ───────────────────────────────────────────────

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


# ── Env file loading ──────────────────────────────────────────────────

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
) -> tuple[dict[str, str], dict[str, set[str]], dict[str, str]]:
    """
    Separate env vars into secrets, allowed hosts, and generator declarations.

    Variables ending in ``_HOSTS`` are parsed as comma-separated host lists.
    Variables ending in ``_GENERATOR`` declare derived secrets.
    All other variables are treated as secrets (including component secrets
    used by generators).

    Returns (secrets, allowed_hosts, generators) where:
    - secrets: {"ANTHROPIC_API_KEY": "sk-ant-...", "APPLE_MUSIC_PRIVATE_KEY": "-----BEGIN..."}
    - allowed_hosts: {"ANTHROPIC_API_KEY": {"api.anthropic.com"}}
    - generators: {"APPLE_MUSIC_TOKEN": "es256_jwt"}
    """
    secrets = {}
    allowed_hosts = {}
    generators = {}

    for key, value in env_vars.items():
        if key.endswith("_HOSTS"):
            # Host allowlist: ANTHROPIC_API_KEY_HOSTS -> ANTHROPIC_API_KEY
            secret_name = key[:-6]  # Remove _HOSTS suffix
            hosts = {h.strip().lower() for h in value.split(",") if h.strip()}
            allowed_hosts[secret_name] = hosts
        elif key.endswith("_GENERATOR"):
            # Generator declaration: APPLE_MUSIC_TOKEN_GENERATOR -> APPLE_MUSIC_TOKEN
            derived_name = key[:-10]  # Remove _GENERATOR suffix
            generators[derived_name] = value
        else:
            secrets[key] = value

    return secrets, allowed_hosts, generators


# ── Main addon ────────────────────────────────────────────────────────

class SecretProxy:
    """
    Scans HTTP request headers and query parameters for {{PLACEHOLDER}} or
    {{namespace:PLACEHOLDER}} patterns and replaces them with secrets from
    1Password Environment .env files.

    Secrets can be either:
    - **Direct**: The value is read straight from the env file
    - **Derived**: A registered generator computes the value from component
      secrets (e.g., signing a JWT from a private key + key ID + issuer)

    Namespacing allows separate 1Password Environments per project. Each
    namespace has its own env file under the namespace directory. Placeholders
    without a namespace use the default env file.

    Security model:
    - Each secret must have a corresponding _HOSTS variable defining allowed destinations
    - Requests to non-allowed hosts are blocked
    - Error messages are generic to prevent information leakage
    - All secret usage is logged for audit purposes
    - Namespaces are fully isolated from each other
    - Generator component secrets have no _HOSTS and cannot be injected
    """

    def __init__(self):
        self.env_file_path: Optional[Path] = None
        self.namespace_dir: Optional[Path] = None

        # Cache for derived (generated) secrets
        self._derived_cache = DerivedSecretCache()

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

    def _load_namespace(
        self, namespace: Optional[str]
    ) -> tuple[dict[str, str], dict[str, set[str]], dict[str, str]]:
        """
        Load and parse secrets, hosts, and generators for a given namespace.

        Returns (secrets, allowed_hosts, generators) or empty dicts if the
        env file doesn't exist.
        """
        path = self._env_file_for_namespace(namespace)
        if path is None:
            return {}, {}, {}

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

    def responseheaders(self, flow: mhttp.HTTPFlow):
        """Enable streaming for Server-Sent Events (SSE) responses.

        Without this, mitmproxy buffers the entire response body before
        relaying it to the client.  LLM APIs stream tokens via SSE, so
        buffering causes the client to hang for the full generation time.
        """
        content_type = flow.response.headers.get("content-type", "")
        if "text/event-stream" in content_type:
            flow.response.stream = True

    def _resolve_generator(
        self,
        flow: mhttp.HTTPFlow,
        key: str,
        namespace: Optional[str],
        ns_label: str,
        gen_name: str,
        secrets: dict[str, str],
        all_placeholder_labels: list[str],
    ) -> Optional[str]:
        """Resolve a derived secret via its registered generator.

        Validates the generator exists, checks required component secrets,
        consults the cache, and calls the generator function if needed.

        Returns the derived value on success.  Returns None and blocks the
        request (setting flow.response) on any failure.
        """
        # Look up generator in the registry
        gen_config = GENERATORS.get(gen_name)
        if gen_config is None:
            self._block_request(
                flow,
                all_placeholder_labels,
                f"Unknown generator '{gen_name}' for {ns_label}{key}",
            )
            return None

        # Validate required component secrets exist
        prefix = _derive_prefix(key)
        for suffix in gen_config["required_suffixes"]:
            component = f"{prefix}{suffix}"
            if component not in secrets:
                self._block_request(
                    flow,
                    all_placeholder_labels,
                    f"Generator '{gen_name}' for {ns_label}{key} requires "
                    f"{ns_label}{component} but it is not defined",
                )
                return None

        # Check cache
        cache_key = f"{namespace}:{key}" if namespace else f":{key}"
        cached = self._derived_cache.get(cache_key)
        if cached is not None:
            return cached

        # Generate
        try:
            value = gen_config["func"](key, secrets)
        except Exception as e:
            self._block_request(
                flow,
                all_placeholder_labels,
                f"Generator '{gen_name}' failed for {ns_label}{key}: {e}",
            )
            return None

        self._derived_cache.set(cache_key, value, gen_config["cache_ttl"])
        ctx.log.info(
            f"secret-proxy: Generated {ns_label}{key} via {gen_name} "
            f"(cached for {gen_config['cache_ttl']}s)"
        )
        return value

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

        # Load and cache secrets per namespace (now includes generators)
        namespace_data: dict[
            Optional[str], tuple[dict[str, str], dict[str, set[str]], dict[str, str]]
        ] = {}
        for namespace in by_namespace:
            namespace_data[namespace] = self._load_namespace(namespace)

        # Validate each placeholder
        for placeholder in unique_placeholders:
            namespace, key = parse_placeholder(placeholder)
            ns_label = f"{namespace}:" if namespace else ""
            secrets, allowed_hosts, generators = namespace_data[namespace]

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

            # Resolve: direct secret or derived via generator
            if key not in secrets:
                if key in generators:
                    value = self._resolve_generator(
                        flow, key, namespace, ns_label,
                        generators[key], secrets, unique_placeholders,
                    )
                    if value is None:
                        # Request was blocked inside _resolve_generator
                        return
                    # Inject the generated value into the secrets dict so the
                    # replacement phase can find it.
                    secrets[key] = value
                else:
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
            secrets, _, _ = namespace_data[namespace]
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
