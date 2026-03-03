# secret-proxy

An HTTP proxy that injects 1Password secrets into requests based on
placeholders, with destination allowlisting to prevent secret exfiltration.
For APIs that require short-lived credentials (e.g., Apple Music JWTs),
the proxy can also derive secrets on the fly from component parts stored
in 1Password — no manual token rotation needed.

Designed to run on a macOS host and serve a Lima NixOS VM over an SSH tunnel,
so secrets never enter the VM.

## How It Works

A client sends a request with placeholders instead of real credentials,
either in headers or query parameters:

```bash
# Using a default (shared) secret in a header
curl -x localhost:17329 https://api.anthropic.com/v1/messages \
  -H "x-api-key: {{ANTHROPIC_API_KEY}}" \
  -H "Content-Type: application/json" \
  -d '{"model": "claude-sonnet-4-20250514", "max_tokens": 1024, "messages": [...]}'

# Using a namespaced (per-project) secret in a header
curl -x localhost:17329 https://api.anthropic.com/v1/messages \
  -H "x-api-key: {{michael:ANTHROPIC_API_KEY}}" \
  -H "Content-Type: application/json" \
  -d '{"model": "claude-sonnet-4-20250514", "max_tokens": 1024, "messages": [...]}'

# Using a secret in a query parameter
curl -x localhost:17329 \
  "https://maps.googleapis.com/maps/api/geocode/json?address=1+Main+St&key={{GOOGLE_MAPS_KEY}}"
```

The proxy validates the destination is allowed for that secret, replaces
the placeholder with the actual value from 1Password, and forwards
the request. The upstream API receives a normal authenticated request.

For derived secrets (like Apple Music JWTs), the proxy reads component
secrets (private key, key ID, team ID) from 1Password, generates the
credential on the fly, caches it until near-expiry, and injects it —
the client uses the same `{{PLACEHOLDER}}` syntax for both.

## Architecture

```
┌─────────────────────────────────────────────────────────────────────────┐
│  HOST (macOS)                                                           │
│                                                                         │
│  ┌──────────────────┐      ┌──────────────────┐                        │
│  │  SECRET PROVIDER │      │  secret-proxy    │                        │
│  │                  │      │  (mitmdump)      │                        │
│  │  1Password Envs  │─────▶│                  │                        │
│  │  (mounted .env)  │      │  1. Finds {{X}}  │                        │
│  │                  │      │  2. Resolves ns  │                        │
│  │  Default env:    │      │  3. Checks HOSTS │                        │
│  │  secrets.env     │      │  4. Validates dst│                        │
│  │                  │      │  5. Generates*   │                        │
│  │  Namespace envs: │      │  6. Replaces     │                        │
│  │  namespaces/     │      │  7. Logs audit   │                        │
│  │    michael/      │      │                  │                        │
│  │      secrets.env │      │  *If _GENERATOR  │                        │
│  └──────────────────┘      └────────┬─────────┘                        │
│                               127.0.0.1:17329                          │
│                                     │                                   │
│                              SSH reverse tunnel                         │
│                              (managed by Lima)                          │
└─────────────────────────────┼───────────────────────────────────────────┘
                              │
┌─────────────────────────────┼───────────────────────────────────────────┐
│  VM (NixOS)                 │                                           │
│                        127.0.0.1:17329                                  │
│                                                                         │
│  ┌────────────────────────────────────────────────────────────────────┐│
│  │  CLIENT APPLICATION                                                ││
│  │                                                                    ││
│  │  # Shared secret (default namespace)                               ││
│  │  requests.post("https://api.anthropic.com/v1/messages",           ││
│  │      headers={"x-api-key": "{{ANTHROPIC_API_KEY}}"})              ││
│  │                                                                    ││
│  │  # Project-specific secret (michael namespace)                     ││
│  │  requests.post("https://api.anthropic.com/v1/messages",           ││
│  │      headers={"x-api-key": "{{michael:ANTHROPIC_API_KEY}}"})      ││
│  │                                                                    ││
│  │  ⚠️  Secrets never enter VM — only placeholders                    ││
│  │  ⚠️  Cannot exfiltrate to unauthorized hosts                       ││
│  └────────────────────────────────────────────────────────────────────┘│
│                                                                         │
└─────────────────────────────────────────────────────────────────────────┘
```

## Namespaces

Namespaces allow separate 1Password Environments for different projects
or contexts. Each namespace has its own `.env` file with its own secrets
and host allowlists, providing full isolation.

### File Layout

```
~/.config/secret-proxy/
├── secrets.env                        # Default namespace (shared secrets)
├── namespaces/
│   ├── michael/
│   │   └── secrets.env                # "michael" namespace secrets
│   └── <other-project>/
│       └── secrets.env                # Other project's secrets
├── secret_proxy.py
└── proxy.log
```

### Placeholder Syntax

```
{{SECRET_NAME}}               # Default namespace
{{michael:SECRET_NAME}}       # "michael" namespace
{{project:SECRET_NAME}}       # "project" namespace
```

The same secret name can exist in multiple namespaces with different values
and different allowed hosts. Namespaces are fully isolated — a secret in
one namespace cannot be accessed from another.

### 1Password Setup for Namespaces

Each namespace maps to a separate 1Password Environment:

1. Open 1Password Desktop → Developer → Environments
2. Create a new Environment named for the namespace (e.g., "michael")
3. Add secrets and `_HOSTS` variables (same format as the default env)
4. Destinations → Local .env file → `~/.config/secret-proxy/namespaces/michael/secrets.env`
5. Click "Mount .env file"

### Nix Configuration

Enable namespaces in the darwin host config:

```nix
modules.dev.secret-proxy = {
  enable = true;
  namespaces = [ "michael" ];
};
```

## Derived Secrets (Generators)

Some APIs require short-lived credentials that are computed from
long-lived component secrets. For example, the Apple Music API requires
a JWT signed with a private key, but the JWT expires every 12 hours.
Rather than manually generating and rotating tokens, the proxy can
derive them on the fly.

### How It Works

A **generator** is a named function registered in the proxy that
produces a secret value from component secrets in the same namespace.
The component secrets (private key, key ID, etc.) live in 1Password
and are never directly injectable — only the derived result is injected
into requests.

When the proxy encounters a placeholder like `{{APPLE_MUSIC_TOKEN}}`,
it checks whether the secret has a corresponding `_GENERATOR` variable.
If so, it:

1. Reads the component secrets from the same namespace's env file
2. Calls the generator function to compute the derived value
3. Caches the result with a TTL (to avoid regenerating on every request)
4. Injects the cached value in place of the placeholder

The client uses the exact same `{{PLACEHOLDER}}` syntax — it doesn't
know or care whether a secret is stored directly or derived.

### Configuration

In your 1Password Environment `.env`, define the component secrets and
a `_GENERATOR` variable that names the generator to use:

```
# Component secrets — these are inputs, never directly injected.
# 1Password resolves op:// refs at mount time; the proxy sees plain values.
APPLE_MUSIC_PRIVATE_KEY=-----BEGIN PRIVATE KEY-----\nMIGT...
APPLE_MUSIC_KEY_ID=ABC123DEFG
APPLE_MUSIC_TEAM_ID=9876543210

# Derived secret — the generator name tells the proxy how to compute it.
# There is no APPLE_MUSIC_TOKEN value — the _GENERATOR tells the proxy
# to produce it on the fly from the component secrets above.
APPLE_MUSIC_TOKEN_GENERATOR=apple_music_jwt
APPLE_MUSIC_TOKEN_HOSTS=api.music.apple.com
```

The `_HOSTS` allowlist still applies — derived secrets get the same
destination validation as regular secrets.

Component secrets (`APPLE_MUSIC_PRIVATE_KEY`, etc.) have no `_HOSTS`
variable, so they can never be injected into any request. They exist
only as inputs to the generator.

### Built-in Generators

#### `apple_music_jwt`

Generates an Apple Music API developer token (ES256-signed JWT).

**Required component secrets** (same namespace):

| Secret | Description |
|--------|-------------|
| `APPLE_MUSIC_PRIVATE_KEY` | MusicKit private key (PEM format, from Apple Developer portal) |
| `APPLE_MUSIC_KEY_ID` | Key ID shown in Apple Developer → Keys |
| `APPLE_MUSIC_TEAM_ID` | Your Apple Developer Team ID |

**Behavior:**
- Signs a JWT with `alg: ES256`, `kid: <key_id>`
- Payload: `iss: <team_id>`, `iat: now`, `exp: now + 12h`
- Caches the token for 11 hours (regenerates 1 hour before expiry)

**Usage from the VM:**

```bash
curl https://api.music.apple.com/v1/catalog/us/songs/203709340 \
  -H "Authorization: Bearer {{APPLE_MUSIC_TOKEN}}"

# Or namespaced
curl https://api.music.apple.com/v1/catalog/us/songs/203709340 \
  -H "Authorization: Bearer {{michael:APPLE_MUSIC_TOKEN}}"
```

### Adding New Generators

To add a new generator, register it in the `GENERATORS` dict in
`secret_proxy.py`:

```python
GENERATORS = {
    "apple_music_jwt": {
        "func": generate_apple_music_jwt,
        "ttl": 11 * 3600,  # Cache for 11h, regenerate before 12h expiry
        "requires": [
            "APPLE_MUSIC_PRIVATE_KEY",
            "APPLE_MUSIC_KEY_ID",
            "APPLE_MUSIC_TEAM_ID",
        ],
    },
    # Add new generators here:
    # "my_custom_jwt": {
    #     "func": generate_my_custom_jwt,
    #     "ttl": 3600,
    #     "requires": ["MY_PRIVATE_KEY", "MY_KEY_ID"],
    # },
}
```

Each generator entry has:

| Field | Description |
|-------|-------------|
| `func` | Callable that receives the namespace's secrets dict and returns the derived value |
| `ttl` | How long (in seconds) to cache the result before regenerating |
| `requires` | List of component secret names that must exist in the same namespace |

The generator function signature:

```python
def generate_my_token(secrets: dict[str, str]) -> str:
    """Receives all secrets from the namespace, returns the derived value."""
    ...
```

### Nix Dependency

Generators that sign JWTs require `PyJWT` and `cryptography` in the
mitmproxy Python environment. The `secret-proxy` Nix module adds these
automatically when the module is enabled:

```nix
mitmproxy = prev.mitmproxy.overridePythonAttrs (old: {
  pythonRelaxDeps = true;
  doCheck = false;
  propagatedBuildInputs = (old.propagatedBuildInputs or []) ++ [
    prev.python3Packages.pyjwt
    prev.python3Packages.cryptography
  ];
});
```

### Generator Caching

Derived secrets are cached in memory with a TTL. The cache key includes
the namespace, so the same generator in different namespaces produces
independent cached values. When the TTL expires, the next request
triggers regeneration — the component secrets are re-read from
1Password at that point, so key rotations in 1Password take effect
automatically on the next cache miss.

## Security Model

### SSH Tunnel (No Network Exposure)

The proxy binds to `127.0.0.1:17329` on the host — it is not reachable from
the network. A separate launchd agent maintains an SSH reverse tunnel
(using Lima's existing SSH control connection) that makes the proxy appear
as `127.0.0.1:17329` inside the VM.

This means no other device on your local network can reach the proxy.

### Destination Allowlisting

Each secret **must** have a corresponding `_HOSTS` variable defining which
hosts can receive it. This applies per-namespace — each namespace's env file
contains its own `_HOSTS` variables:

```
# In default secrets.env
ANTHROPIC_API_KEY=sk-ant-shared-...
ANTHROPIC_API_KEY_HOSTS=api.anthropic.com

# In namespaces/michael/secrets.env
ANTHROPIC_API_KEY=sk-ant-michael-...
ANTHROPIC_API_KEY_HOSTS=api.anthropic.com
```

If a request uses `{{michael:ANTHROPIC_API_KEY}}` with any host other than
what's in the michael namespace's `ANTHROPIC_API_KEY_HOSTS`, it is blocked.

**Fail-closed behavior:**
- Secret exists but no `_HOSTS` defined → blocked
- Secret doesn't exist → blocked
- Host not in allowlist → blocked
- Namespace not configured → blocked
- Namespace env file missing → blocked
- Generator named but not registered → blocked
- Generator's required component secrets missing → blocked
- Generator function throws an error → blocked

### Generic Error Messages

To prevent information leakage, all blocked requests return the same error:

```
403 Forbidden

Request blocked by secret-proxy policy.

If you believe this is an error, check the proxy logs on the host.
```

The specific reason (missing secret, missing hosts config, host not allowed,
unknown namespace) is logged only on the host where the VM cannot read it.

### Audit Logging

All requests involving secrets are logged in structured JSON:

```json
{"timestamp": "2026-02-04T12:34:56Z", "secrets": ["ANTHROPIC_API_KEY"], "method": "POST", "host": "api.anthropic.com", "path": "/v1/messages", "blocked": false}
```

Namespaced secrets include the namespace prefix in the log:

```json
{"timestamp": "2026-02-04T12:34:56Z", "secrets": ["michael:ANTHROPIC_API_KEY"], "method": "POST", "host": "api.anthropic.com", "path": "/v1/messages", "blocked": false}
```

Blocked requests include the reason:

```json
{"timestamp": "2026-02-04T12:34:57Z", "secrets": ["michael:ANTHROPIC_API_KEY"], "method": "POST", "host": "evil.com", "path": "/steal", "blocked": true, "reason": "Host 'evil.com' not allowed for michael:ANTHROPIC_API_KEY"}
```

### Threat Mitigation

| Threat | Mitigation |
|--------|------------|
| VM exfiltrates secret to attacker server | Destination allowlisting blocks unauthorized hosts |
| VM reads secrets from memory | Secrets never enter VM — only placeholders |
| Network attacker reaches proxy | Bound to 127.0.0.1, accessible only via SSH tunnel |
| Attacker probes for secret names | Generic error messages prevent enumeration |
| Cross-namespace access | Each namespace is isolated with its own env file |
| 1Password locked | Secrets unavailable, requests fail (fail-closed) |
| Placeholder in response | Not scanned — only request headers and query params |
| Unknown namespace referenced | Request blocked (fail-closed) |
| Generator component secrets exfiltrated | Component secrets have no `_HOSTS`, cannot be injected into any request |
| Derived token intercepted | Tokens are short-lived (e.g., 12h JWTs); private keys stay on host |
| Generator misconfigured (missing inputs) | Missing component secrets cause fail-closed error, logged on host |

## Setup

### Prerequisites

- 1Password Desktop with Developer experience enabled
- The `secret-proxy` nix-darwin module enabled on the host
- The Lima NixOS VM configured as a proxy client

### 1. Enable the Module (Host)

In your darwin host config (e.g., `hosts/aarch64-darwin/arbitrary/default.nix`):

```nix
modules.dev.secret-proxy = {
  enable = true;
  namespaces = [ "michael" ];  # Optional: per-project namespaces
};
```

This installs mitmproxy, deploys the proxy script, and creates a launchd
agent that runs automatically.

### 2. Configure 1Password Environments

#### Default Environment (shared secrets)

1. Open 1Password Desktop
2. Settings → Developer → Enable "Show 1Password Developer experience"
3. Developer → Environments → New Environment
4. Add your secrets **and their allowed hosts** (see `secrets.env.example`)
5. Destinations → Configure "Local .env file"
6. Set path to `~/.config/secret-proxy/secrets.env`
7. Click "Mount .env file"

#### Namespace Environments (per-project secrets)

For each namespace (e.g., "michael"):

1. Developer → Environments → New Environment (name it "michael")
2. Add project-specific secrets and `_HOSTS` variables
3. Destinations → Local .env file
4. Set path to `~/.config/secret-proxy/namespaces/michael/secrets.env`
5. Click "Mount .env file"

See `namespaces/michael/secrets.env.example` for the format.

**Important:** 1Password must remain unlocked for secrets to be available.
If it locks during an agent run, all requests with placeholders will fail.
For unattended/long-running workloads, consider a
[1Password Service Account](https://developer.1password.com/docs/service-accounts/).

### 3. Generate and Deploy the mitmproxy CA Certificate

On first run, mitmproxy generates a CA certificate. The VM needs to trust
this certificate to allow HTTPS inspection.

```bash
# If mitmproxy hasn't run yet, start it briefly to generate the CA
mitmdump --listen-port 0 &
sleep 2
kill %1

# Copy the public CA cert into the nix-config repo
cp ~/.mitmproxy/mitmproxy-ca-cert.pem ~/Code/nix-config/configs/secret-proxy/

# Commit it (this is the public cert, safe to commit)
cd ~/Code/nix-config
jj add configs/secret-proxy/mitmproxy-ca-cert.pem
```

### 4. Configure the VM (Lima NixOS)

The `lima-dev` host config includes proxy client configuration that:
- Sets `HTTP_PROXY` and `HTTPS_PROXY` to `127.0.0.1:17329`
- Trusts the mitmproxy CA certificate via `security.pki.certificateFiles`
- Excludes local addresses via `NO_PROXY`

The SSH reverse tunnel is managed automatically by a `secret-proxy-tunnel`
launchd agent on the host. It piggybacks on Lima's existing SSH control
connection — no extra configuration on the VM or Lima yaml is needed.

### 5. Rebuild Both Systems

```bash
# Host (macOS)
darwin-rebuild switch --flake ~/Code/nix-config

# VM (NixOS) — from inside the VM
sudo nixos-rebuild switch --flake ~/Code/nix-config#lima-dev
```

## Placeholder Syntax

### Default Namespace

Pattern: `{{VARIABLE_NAME}}`

- Must start with letter or underscore
- Can contain letters, numbers, underscores
- Case-sensitive
- Scanned in request headers and query parameters (not bodies)

Examples:
```
{{ANTHROPIC_API_KEY}}
{{OPENAI_API_KEY}}
{{GITHUB_TOKEN}}
```

### Namespaced

Pattern: `{{namespace:VARIABLE_NAME}}`

- Namespace must start with letter or underscore
- Namespace can contain letters, numbers, underscores
- Colon separates namespace from key
- Key follows the same rules as default placeholders

Examples:
```
{{michael:ANTHROPIC_API_KEY}}
{{michael:OPENAI_API_KEY}}
{{acme:GITHUB_TOKEN}}
```

## Usage

From inside the VM, any tool that respects `HTTP_PROXY`/`HTTPS_PROXY`
will automatically route through the proxy:

```bash
# Using default (shared) secrets
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: {{ANTHROPIC_API_KEY}}" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model": "claude-sonnet-4-20250514", "max_tokens": 1024, "messages": [...]}'

# Using namespaced secrets
curl https://api.anthropic.com/v1/messages \
  -H "x-api-key: {{michael:ANTHROPIC_API_KEY}}" \
  -H "anthropic-version: 2023-06-01" \
  -H "content-type: application/json" \
  -d '{"model": "claude-sonnet-4-20250514", "max_tokens": 1024, "messages": [...]}'
```

```python
# Python — namespaced secret
import httpx

response = httpx.post(
    "https://api.anthropic.com/v1/messages",
    headers={
        "x-api-key": "{{michael:ANTHROPIC_API_KEY}}",
        "anthropic-version": "2023-06-01",
        "content-type": "application/json",
    },
    json={"model": "claude-sonnet-4-20250514", "max_tokens": 1024, "messages": [...]},
)
```

Or specify the proxy explicitly:

```bash
curl -x http://127.0.0.1:17329 https://api.anthropic.com/v1/messages \
  -H "x-api-key: {{michael:ANTHROPIC_API_KEY}}"
```

## Troubleshooting

### Check if the proxy is running (host)

```bash
launchctl list | grep secret-proxy
# Or check logs:
tail -f ~/.config/secret-proxy/proxy.log
tail -f ~/.config/secret-proxy/proxy.err
```

### Check if the tunnel is working (VM)

```bash
curl -s -o /dev/null -w "%{http_code}" http://127.0.0.1:17329/
# Should return 400 (mitmproxy is running but this isn't a proxy request)
# Connection refused = tunnel not working
```

### Request returns 403

Check the host-side logs for the specific reason:

```bash
grep "secret-proxy-audit" ~/.config/secret-proxy/proxy.log | tail -5
```

Common causes:
- Secret not defined in 1Password Environment
- `_HOSTS` variable missing for the secret
- Request host not in the allowed hosts list
- Namespace not configured or env file not mounted
- 1Password is locked

### HTTPS certificate errors

The VM needs to trust the mitmproxy CA. Verify:

```bash
# In the VM
curl -v https://api.anthropic.com 2>&1 | grep -i "SSL\|certificate"
```

If you see certificate errors, ensure:
1. `mitmproxy-ca-cert.pem` exists in `configs/secret-proxy/`
2. It's referenced in `security.pki.certificateFiles` in the VM config
3. You've rebuilt the VM's NixOS config

### Log Rotation

Logs are written to `~/.config/secret-proxy/proxy.log` and `proxy.err`.
Consider setting up rotation via macOS `newsyslog`. Create
`/etc/newsyslog.d/secret-proxy.conf`:

```
# logfile                                              mode count size when flags
/Users/YOUR_USERNAME/.config/secret-proxy/proxy.log    644  5     1000 *    J
/Users/YOUR_USERNAME/.config/secret-proxy/proxy.err    644  5     1000 *    J
```

## Limitations

- **Headers and query parameters only**: Body placeholders are not scanned (by design)
- **HTTPS requires CA**: The VM must trust the mitmproxy CA certificate
- **1Password must be unlocked**: Secrets require an unlocked vault
  (consider Service Accounts for unattended use)
- **No rate limiting**: Relies on upstream API rate limits
- **Generator cache is in-memory**: Restarting the proxy clears cached
  derived secrets (they regenerate on next request, so this only adds
  a one-time latency cost)
- **Generators run on the proxy hot path**: A slow generator (e.g., HSM
  signing) would add latency to the first request after cache expiry
