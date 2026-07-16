# Make secret-proxy headless with a 1Password service account

This ExecPlan is a living document. The sections Progress, Surprises & Discoveries,
Decision Log, and Outcomes & Retrospective must be kept up to date as work proceeds.

## Purpose / Big Picture

The Lima development VM currently obtains secrets from a proxy on the macOS host. The
VM sends placeholders such as `{{GITHUB_TOKEN}}` and
`{{scherzo:GITHUB_TOKEN}}`; the host replaces them only for allowlisted destinations.
The host currently reads 1Password Environment local `.env` destinations, which are
UNIX named pipes. Their first read after 1Password locks or restarts requires a GUI
approval, and an unanswered prompt can block the entire proxy.

After this change, the proxy can authenticate to 1Password with a narrowly scoped
service account and read the default and Scherzo Environments without a desktop prompt.
The service-account token remains encrypted in the repository with Homeage, is decrypted
only on the macOS host, and never enters the Nix store or VM. An operator can prove the
change works by quitting or locking 1Password, restarting the proxy, authenticating to
GitHub through both namespaces, and observing fail-closed HTTP 403 responses for a
reserved unauthorized destination.

## Problem Framing and Constraints

The current proxy transport, certificate trust, namespace syntax, destination
allowlisting, audit logs, and SSH reverse tunnel already work and must remain intact.
Only the host-side source of Environment variables should change. The new path must not
put the service-account token or fetched API credentials in Git, the Nix store, command
arguments, logs, or the VM.

1Password's stable CLI 2.34.1 does not include `op environment read`; that command exists
only in beta releases. The beta must therefore be pinned as a separate Nix package used
only by secret-proxy. The normal stable `op` package remains unchanged for Homeage and
interactive work. The current Homeage identity uses `age-plugin-op`, so provisioning an
updated encrypted token remains interactive; this plan targets headless runtime and
reboots, not noninteractive first-time provisioning.

## Strategy Overview

Add a dedicated package for 1Password CLI beta 2.38.0-beta.01. Add a pure-Python secret
provider module beside `packages/secret-proxy/secret_proxy.py`. The provider invokes the
beta CLI with `OP_SERVICE_ACCOUNT_TOKEN` set only in the child process environment,
loads a configured 1Password Environment ID, and caches the returned `.env`-formatted
content in host memory for a bounded interval. The proxy continues parsing variables,
applying `_HOSTS` policy, generating derived credentials, and auditing requests exactly
as before.

The existing local-file provider remains available as the default during implementation
and as an immediate rollback. Its FIFO read changes from an unbounded Python `open()` to
a bounded `cat` subprocess, so a missed authorization prompt fails closed instead of
freezing every proxied request indefinitely.

The nix-darwin module gains explicit provider options. Service-account mode passes only
an absolute CLI path, token-file path, non-secret Environment ID mapping, and timeout
settings to mitmproxy. It does not read the token during Nix evaluation. The Gray Area
host will switch providers only after the encrypted token and IDs are available.

## Alternatives Considered

Leaving 1Password unlocked and disabling auto-lock would avoid some prompts but would
not survive application restarts and would weaken workstation security. It is rejected.

Using the 1Password Python SDK would avoid a beta CLI process, but Environment support in
the SDK is also beta and would add a larger Python dependency to mitmproxy. The isolated
CLI package is smaller and easier to replace when stable CLI support arrives.

Removing 1Password and storing all API credentials with Homeage would make runtime
simple, but it would duplicate every secret onto the host and discard Environment
rotation. Storing only the scoped service-account bootstrap token with Homeage retains
1Password as the source of truth.

## Risks and Countermeasures

A beta CLI may change output or authentication behavior. Pure-Python tests cover command
construction and parsing, the package install check verifies the expected command exists,
and rollout keeps the FIFO backend available. The real service account is validated
before provider cutover.

A child process could hang on network or provider failure. Every CLI invocation has a
strict timeout, errors return no variables, and requests fail closed. The legacy FIFO
reader receives the same bounded behavior.

Frequent Environment reads could hit service-account rate limits. Successful results are
cached by namespace in memory. Cache duration is configurable; failures are not cached,
so recovery does not require restarting the daemon.

A token could leak through Nix or logs. The Nix module accepts only a runtime file path.
The provider reads that file at request time, passes the token only via child process
environment, never logs command output, and tests assert error messages exclude captured
stdout and stderr.

A bad rollout could interrupt all proxied development traffic. The provider switch is a
single host option. Recovery is to switch back to `environmentFiles`, rebuild Gray Area,
and authorize the existing FIFO destinations.

## Progress

- [x] (2026-07-16 16:08Z) Verified the existing proxy, Homeage, host module, stable CLI version, and beta CLI download layout.
- [x] (2026-07-16 16:08Z) Chose an additive CLI-backed provider with the FIFO backend retained for rollback.
- [x] (2026-07-16 16:13Z) Packaged and verified 1Password CLI beta 2.38.0-beta.01 for supported systems.
- [x] (2026-07-16 16:22Z) Added and unit-tested bounded file and service-account Environment providers.
- [x] (2026-07-16 16:22Z) Integrated provider selection into the mitmproxy addon without changing policy behavior.
- [x] (2026-07-16 16:29Z) Added nix-darwin provider options, assertions, and launch arguments.
- [x] (2026-07-16 16:37Z) Updated operator documentation and ran formatting, parsing, nine unit tests, package builds, current-host evaluation, and a synthetic service-account launch-argument evaluation.
- [x] (2026-07-16 16:42Z) Obtained all three Environment IDs, verified service-account access, and encrypted its token locally with Homeage without retaining clipboard or plaintext data.
- [ ] Switch Gray Area to service-account mode, rebuild, and run allowed and blocked end-to-end tests with the 1Password desktop app unavailable (completed: configuration committed and generation built; blocked: activation requires an administrator password in an interactive terminal).

## Surprises & Discoveries

- Observation: A direct request to mitmproxy's listener returns HTTP 502 rather than the README's documented HTTP 400.
  Evidence: The live VM reached `127.0.0.1:17329` and received 502 while normal proxied HTTPS succeeded.

- Observation: The current FIFO reader blocks the mitmproxy event loop indefinitely while 1Password waits for approval.
  Evidence: A GitHub request timed out after 30 seconds with no audit record; restarting the launch agent and approving the prompt allowed the same request to succeed.

- Observation: Stable `op` 2.34.1 lacks the Environment subcommand even though its version is newer than the first beta that introduced it.
  Evidence: `op environment read --help` reports `unknown command`, while beta 2.38.0-beta.01 exposes the command.

- Observation: Gray Area declares a `michael` namespace in addition to the default and Scherzo namespaces requested for this migration.
  Evidence: `hosts/aarch64-darwin/gray-area/default.nix` lists both `michael` and `scherzo`; service-account maps intentionally allow an omitted namespace to fail closed.

- Observation: Repository-wide `nix flake check --no-build` reaches an unrelated pre-existing invalid Linux derivation while evaluating `nixosConfigurations.lima-dev` from Darwin.
  Evidence: The check repeatedly fails on missing store path `yvv5b8kasbhy7258yqmmcwdisfhqd56x-cabal2nix-cachix.drv`, including with `eval-cache` disabled. The aarch64-darwin formatting check, Gray Area system build, both changed packages, and synthetic service-account module evaluation all pass.

- Observation: Resolving the saved service-account item through stable `op item get` still requires one-time desktop authorization during provisioning.
  Evidence: The metadata-only command initially timed out and then succeeded after approval, but three subsequent `op read` attempts timed out without approval. Every incomplete Age output was removed. Provisioning will use a one-time clipboard-to-Age pipe and immediately clear the clipboard instead; no plaintext file is created.

## Decision Log

- Decision: Keep the existing FIFO provider and make provider selection explicit rather than replacing it immediately.
  Rationale: This provides a one-option rollback until the real service account passes end-to-end validation.
  Date: 2026-07-16

- Decision: Pin a separate beta CLI package instead of overriding system-wide `_1password-cli`.
  Rationale: Homeage and interactive tooling remain on stable software; only the feature that requires beta code receives it.
  Date: 2026-07-16

- Decision: Store only the service-account token with Homeage and keep fetched Environment values in process memory.
  Rationale: The token is the minimum bootstrap credential required for headless access, while actual API credentials remain centralized in 1Password and outside the VM.
  Date: 2026-07-16

- Decision: Use bounded synchronous subprocesses rather than adding an asynchronous provider framework.
  Rationale: Environment reads happen only on cache misses, strict timeouts bound impact, and this is the smallest change compatible with mitmproxy's synchronous request hook.
  Date: 2026-07-16

- Decision: Require a default Environment ID but allow named namespaces to be omitted from the service-account map.
  Rationale: The requested rollout covers default and Scherzo. An omitted namespace fails closed, allowing Michael to remain unavailable until its Environment is deliberately granted to this service account.
  Date: 2026-07-16

- Decision: Refuse service-account token files readable by group or other users.
  Rationale: Homeage produces mode 0400 files, and failing closed on broader permissions prevents accidental plaintext exposure during manual recovery.
  Date: 2026-07-16

- Decision: Fall back to a one-time clipboard pipe for initial token encryption when desktop CLI authorization cannot complete.
  Rationale: The token remains local and is streamed directly into Age, the clipboard is cleared immediately, and failed encryption removes its output. This is safer than a plaintext temporary file or asking the operator to expose the token in chat.
  Date: 2026-07-16

## Outcomes & Retrospective

The implementation milestones before secret handoff are complete in three focused commits. The stable CLI remains unchanged, beta CLI use is isolated, the provider has nine unit tests, FIFO reads are bounded, and both current and future launch configurations evaluate. Gray Area remains on the proven Environment-file backend, so stopping here does not disrupt development.

The service account successfully read the default, Scherzo, and Michael Environments through the pinned beta CLI. Its token is committed only as an Age-encrypted file, the clipboard was cleared, host configuration and launch arguments contain no plaintext token, and the service-account generation builds. Deployment remains incomplete because this harness cannot satisfy macOS sudo authentication; the operator must activate the built configuration interactively before end-to-end headless acceptance can be tested.

## Context and Orientation

`packages/secret-proxy/secret_proxy.py` is a mitmproxy addon. It scans outgoing request
headers and query parameters for placeholders, loads variables from a default or named
namespace, verifies each secret's `_HOSTS` allowlist, replaces placeholders, and writes
structured audit records. `packages/secret-proxy/default.nix` installs that script and
the public mitmproxy CA certificate.

`modules/darwin/dev/secret-proxy.nix` defines the nix-darwin options and two user launch
agents. `secret-proxy` runs mitmdump on host loopback port 17329. `secret-proxy-tunnel`
uses Lima's SSH control socket to expose that host port as loopback port 17329 in the VM.
`hosts/aarch64-darwin/gray-area/default.nix` enables the module with `michael` and
`scherzo` namespaces.

`modules/homeage.nix` integrates Homeage. On Darwin, decrypted files live under
`$HOME/.config/age/secrets`; files are mode 0400. The encrypted source files under
`configs/` are safe to commit. The configured age identity is backed by `age-plugin-op`,
so adding or re-decrypting secrets can require interactive 1Password approval.

`packages/age-with-plugins.nix` intentionally continues using stable
`_1password-cli`. The new beta package is private to secret-proxy.

## Preconditions and Verified Facts

The repository uses Jujutsu, and the initial working copy was clean at commit `31197a5`.
Gray Area is an Apple Silicon Darwin host. The Lima VM is running NixOS generation 7,
trusts the committed mitmproxy CA, and reaches the host tunnel. Default
`{{GITHUB_TOKEN}}` authenticated as `bromanko`; `{{scherzo:GITHUB_TOKEN}}` authenticated
as `bromanko-agent`; both were blocked for `not-allowed.invalid`.

The beta 2.38.0-beta.01 downloads use the same archive layout as the stable Nix package. The dedicated package builds on aarch64-darwin, reports the pinned version, and its install check confirms `op environment read --help` is available.
The verified unpacked hashes are:

- aarch64-darwin: `sha256-xqeQIn2NlRkUkUzDiCCW64Lf2mnZTgp/22R/dCStV/8=`
- aarch64-linux: `sha256-gRG1hQKkv/+8sC2nNbhYn7BYnzuc3rU1yOLMVQu+z90=`
- x86_64-linux: `sha256-xRmqPvl961zDnwFAVaSGUpU3ex7L3j+CtBLK8/Vys7E=`

The service account has been created. The non-secret Environment IDs are default
`23cige3iryi55h4p2h5pmqcppa`, Scherzo `6yr7tvsgkqeipnpaorm2kmbubu`, and Michael
`jzrtussqcnihcskljt5vcpl5ey`. Its saved 1Password item ID is
`6vt7pfcfipigtzta5ogxsfecea`. The token itself must never be pasted into this plan,
source files, chat output, or command-line arguments.

## Scope Boundaries

This work changes only the host's Environment-variable source, its configuration, tests,
and documentation. Placeholder syntax, allowlist semantics, generators, Context Lens,
audit shape, CA distribution, tunnel behavior, VM proxy variables, and Scherzo
application code remain unchanged.

The plan does not make Lima start automatically, convert the user launch agents into
system daemons, remove the 1Password desktop application, or make Homeage provisioning
noninteractive. It does not place Environment values into Homeage.

## Milestones

The first milestone packages the beta CLI and proves the exact binary exposes
`op environment read`. This validates the highest external dependency risk before proxy
code depends on it.

The second milestone introduced a standalone provider module with nine passing unit tests. It proves
bounded FIFO reads, service-account command construction, token isolation, namespace
mapping, caching, timeout handling, and safe errors without requiring mitmproxy or a real
service account.

The third milestone integrates the provider into secret-proxy and nix-darwin while
leaving Gray Area on the legacy backend. A full host evaluation proves existing systems
still build before any secret is required.

The fourth milestone is the explicit secret handoff. The operator supplies two
Environment IDs and makes the service-account token available locally without exposing
it in conversation. The token is encrypted into a new `.age` source, Gray Area switches
providers, and the host is rebuilt.

The final milestone validates headless operation. With 1Password locked or quit, both
GitHub identities must authenticate through the VM, both unauthorized `.invalid`
requests must return the generic 403 response, and four matching audit records must
contain names and policy results but no values.

## Plan of Work

Create `packages/1password-cli-beta.nix` by adapting the stable nixpkgs binary package to
the beta archive URLs and verified hashes. Limit its metadata to the three repository
systems and include an install check for both version and Environment command help.

Create `packages/secret-proxy/secret_provider.py`. Define `SecretProviderError`,
`parse_env_content`, `EnvironmentFileProvider`, and `OnePasswordServiceAccountProvider`.
Both providers expose `load(namespace: Optional[str]) -> dict[str, str]`. The service
provider accepts an executable path, token file, mapping whose `default` key represents
the unqualified namespace, cache and command timeouts, and injectable runner and clock
for tests.

Create `packages/secret-proxy/test_secret_provider.py` using only `unittest` and
`unittest.mock`. Update `packages/secret-proxy/default.nix` to run the tests and install
the provider beside the addon.

Modify `packages/secret-proxy/secret_proxy.py` to register provider options, construct the
selected provider during configuration, and call it from `_load_namespace`. Keep secret
parsing, policy, replacement, and audit logic in the addon. Provider errors are logged
without command output and produce empty namespace data, which makes the request fail
closed with the existing generic client response.

Modify `modules/darwin/dev/secret-proxy.nix` to add `provider`,
`environmentFiles.readTimeoutSeconds`, and a `serviceAccount` option group containing
token file, Environment ID mapping, cache TTL, command timeout, and package. Add an
assertion that service-account mode has a `default` ID. Named namespaces may be omitted
and then fail closed. Build backend-specific mitmdump arguments; never read the token in
Nix.

Update `packages/secret-proxy/README.md` to describe both backends, headless setup,
Homeage token handling, timeout behavior, and rollback. Correct the direct listener
health check to accept any HTTP response as reachability rather than promise HTTP 400.

After secret details are available, add an encrypted token source under
`configs/secret-proxy/`, declare its Homeage file in
`hosts/aarch64-darwin/gray-area/default.nix`, add the non-secret Environment IDs there,
and select service-account mode.

## Concrete Steps

From the repository root, build and inspect the beta package:

    nix build '.#1password-cli-beta'
    ./result/bin/op --version
    ./result/bin/op environment read --help

Expect version `2.38.0-beta.01` and help beginning with “Read environment variables from
a 1Password Environment.”

Run provider tests through the package:

    nix build '.#secret-proxy'

Expect all unit tests to pass before the derivation installs its files.

Format and parse Nix changes:

    nixfmt packages/1password-cli-beta.nix modules/darwin/dev/secret-proxy.nix \
      packages/secret-proxy/default.nix hosts/aarch64-darwin/gray-area/default.nix
    nix-instantiate --parse packages/1password-cli-beta.nix
    nix-instantiate --parse modules/darwin/dev/secret-proxy.nix

Evaluate the Gray Area host before provider cutover:

    nix build '.#darwinConfigurations.gray-area.system'

Expect a successful build with the current Environment-file backend still selected.

Commit the package and provider implementation only after all preceding checks pass.
Use a subject such as `Add headless secret proxy provider`.

At the secret handoff, obtain the default and Scherzo Environment IDs from 1Password's
“Manage environment” view. Encrypt the service-account token through the existing age
workflow without a plaintext intermediate or shell argument. Then rebuild Gray Area and
restart the proxy.

## Testing and Falsifiability

`packages/secret-proxy/test_secret_provider.py` must contain tests with the following
concrete assertions:

- Parsing ignores comments and malformed lines, strips matching outer quotes, preserves
  equals signs in values, and returns ordinary key/value strings.
- The file provider resolves the default path and named namespace path and parses a
  successful bounded reader result.
- A timed-out file read raises `SecretProviderError` without including partial secret
  output.
- The service provider maps `None` to the `default` Environment ID and `scherzo` to its
  configured ID.
- The child command is exactly `<op> environment read <id>`, receives the stripped token
  through `OP_SERVICE_ACCOUNT_TOKEN`, and does not inherit `OP_CONNECT_HOST` or
  `OP_CONNECT_TOKEN`.
- Two loads before cache expiry invoke the CLI once; a load after expiry invokes it
  again.
- Missing namespace IDs, missing or empty token files, nonzero CLI exits, and CLI
  timeouts all raise safe errors. Error text must not contain fake token, stdout secret,
  or stderr diagnostic fixture values.

Package tests falsify the external assumption by failing if beta `op` lacks the
Environment command. Host evaluation falsifies Nix wiring assumptions. End-to-end tests
falsify the headless claim by running with the desktop provider unavailable.

## Validation and Acceptance

Implementation before secret handoff is accepted when the beta package builds, provider
unit tests pass, all edited Nix parses and formats, and Gray Area evaluates without
switching away from its working FIFO backend.

Deployment is accepted only when, with 1Password locked or quit:

- A VM GraphQL viewer request with `{{GITHUB_TOKEN}}` returns HTTP 200 and login
  `bromanko`.
- The same request with `{{scherzo:GITHUB_TOKEN}}` returns HTTP 200 and login
  `bromanko-agent`.
- Requests carrying each placeholder to `http://not-allowed.invalid/` return HTTP 403
  with the generic policy body.
- Host audit logs contain allowed `api.github.com` and blocked
  `not-allowed.invalid` entries for each namespace and no secret values.
- Restarting the launch agent produces no GUI prompt.

## Rollout, Recovery, and Idempotence

Code and module changes are additive. Before secret handoff, behavior is unchanged apart
from the FIFO timeout. Provider cutover occurs only after a direct service-account CLI
read succeeds. The encrypted token can be regenerated safely at the same path, and
Homeage activation can be rerun.

If the beta CLI, token, Environment permissions, or parser fails, switch the host option
back to `environmentFiles`, rebuild, restart the proxy, unlock 1Password, and authorize
the FIFO destinations. The existing paths are not removed during this rollout.

Never test allowlist failure against a real unauthorized host. Use the reserved
`.invalid` top-level domain so even a policy regression cannot transmit a secret.

## Artifacts and Notes

The live pre-change successful audit evidence was:

    GITHUB_TOKEN: host=api.github.com blocked=false
    scherzo:GITHUB_TOKEN: host=api.github.com blocked=false
    GITHUB_TOKEN: host=not-allowed.invalid blocked=true
    scherzo:GITHUB_TOKEN: host=not-allowed.invalid blocked=true

No secret values were printed while collecting this evidence.

## Interfaces and Dependencies

`packages/secret-proxy/secret_provider.py` must expose:

    class SecretProviderError(RuntimeError): ...

    def parse_env_content(content: str) -> dict[str, str]: ...

    class EnvironmentFileProvider:
        def load(self, namespace: Optional[str]) -> dict[str, str]: ...

    class OnePasswordServiceAccountProvider:
        def load(self, namespace: Optional[str]) -> dict[str, str]: ...

The service provider command is:

    op environment read <environment-id>

Authentication is passed only in the child environment variable
`OP_SERVICE_ACCOUNT_TOKEN`. The provider must remove `OP_CONNECT_HOST` and
`OP_CONNECT_TOKEN`, because Connect settings take precedence over service accounts.

The nix-darwin module accepts the service-account token as a runtime path and Environment
IDs as ordinary configuration strings. IDs are identifiers, not credentials. The beta
CLI package is referenced by absolute Nix store path in launch arguments; the service
account token's contents are not.
