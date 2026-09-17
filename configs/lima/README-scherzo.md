# Lima Scherzo connectivity prototype

Current sizing: both runners have 3 CPUs, 8 GiB RAM, 100 GiB disk and 4 GiB swap.
See [the dual-runner trial status](README-sizing.md) for preservation, boot override
and remaining qualification prerequisites. Older entries below are historical.

## Scherzo Cloud 0.36.0 rollout (2026-09-17)

Both runner VMs now use Scherzo Cloud 0.36.0. The guest-only activations preserved
the existing enrollment credentials and produced these systems:

- `lima-scherzo`: `/nix/store/l6ykggx5h2b3kx37a244d2da63bjy4j6-nixos-system-lima-scherzo-26.11.20260818.0ae2bc1`
- `lima-scherzo-2`: `/nix/store/481ddh3l3njv6fqa95w2qccykrg2dks4-nixos-system-lima-scherzo-2-26.11.20260818.0ae2bc1`

Both services are active and advertise 0.36.0. A controlled assignment attempt
still received an undecodable gateway frame after its opening handshake, so both
registrations were returned to draining with zero assignments. LIV-2264 and
LIV-2284 remain queued; do not re-enable these runners until the remaining
runner/gateway version mismatch is resolved.

## Shared validation capacity (2026-09-14)

Both VMs now have narrow `95-validation-capacity.conf` service overrides in
`/etc/systemd/system.control/scherzo-runner.service.d/`. They set
`REPO_CHECK_JOBS=1`, `REPO_CHECK_LOCK=/run/scherzo-cloud/repo-check.lock`,
`CARGO_BUILD_JOBS=1`, and
`RUSTC_WRAPPER=/var/lib/scherzo-validation/serialized-rustc`. The compiler wrapper
uses a separate `/run/scherzo-cloud/rustc.lock`. Both runners remain drained.

Cloud PR #1487 must reach the selected source before ticket dispatch: it preserves
these controls through clean validation. `REPO_CHECK_*` deliberately avoids the
engine-reserved `SCHERZO_*` prefix. These controls coordinate aggregates and
Cargo compiler invocations, not arbitrary tests or all memory use. A loaded
simultaneous two-workflow trial remains outstanding.

The common NixOS declaration supplies the same limits with a store-backed compiler
wrapper. After deliberately deploying that declaration, remove only the temporary
`95-validation-capacity.conf` override and verify the effective service settings.
Do not bundle unrelated pending NixOS changes into this rollout.

## Cargo memory-pressure mitigation (2026-09-09)

The reviewed implementation run for LIV-2112,
`run_01m23kz36a4z19pt1vqfyytv3d`, was interrupted during implementation by a
VM-wide OOM. Two concurrent rustc processes exhausted RAM and nearly all 2 GiB
of swap. Systemd's OOMPolicy=stop then stopped the runner. Its exported result,
controller provenance, and claim receipt survived, but no patch or native agent
session was found in the retained artifacts or remaining workspace directories.
No automatic retry was submitted.

After confirming both Cloud and local quiescence, the runner now supplies
`CARGO_BUILD_JOBS=1`. Because repository clean validation shells drop that
variable but preserve HOME, startup also materializes `.cargo/config.toml` with
`build.jobs = 1`, from the same declarative value. A child process inherited the
limit; a separate Cargo configuration read with that environment variable absent
also resolved build.jobs to 1. The guest-only activation succeeded:
`/nix/store/nz1j1hnmb8c1v2bp4cir2d0ky8lzz36q-nixos-system-lima-scherzo-26.11.20260818.0ae2bc1`.
This is a concurrency default, not a hard memory bound; explicit Cargo overrides
or alternate CARGO_HOME values can supersede it.

With operator approval and both assignment counts zero, lima-scherzo was stopped,
resized in place to 8 GiB, and started again. The declarative template in
`scherzo.yaml` now specifies 8 GiB as well. CPUs remain 2, disk remains 60 GiB,
and the original enrollment credential is unchanged. New runner boot:
`rbt_01m241w1zsjnhe62pje6qj6sjb`. Guest memory reports 7.7 GiB usable, and 2 GiB
swap remains configured. Native isolated Python Linear reads, GitHub reads,
Git/askpass authentication, and Cargo's one-job setting all passed after boot.
Cloud is online and draining with zero assignments; local assignments are also
zero. No task retry has been submitted.

gray-area has 24 GiB and lima-dev remains configured for 12 GiB; full VM allocations
leave 4 GiB for the host. Memory pressure should be watched under simultaneous
load. lima-dev kept its existing host-agent PID and was not restarted; the shared
proxy was not changed or restarted.

## Shared Linear transport rollout (2026-09-09)

The declarative runner configuration now supplies `LINEAR_API_KEY` as a public
placeholder plus `LINEAR_PROXY_URL` and `LINEAR_PROXY_CA_FILE`. The Python
script-name wrapper is removed from that candidate; Python is a normal package.
The shared Cloud `linear_graphql.py` client owns this routing, including calls
through implementation's pinned isolated interpreter. No real credential or CA
private key is added. Direct mode ignores ambient proxies; configured proxy mode
ignores bypass settings and has no direct fallback.

This update is **activated** after Cloud PR #1342 merged as
`cc17e36ecdc261ea5d8f68b094ba21802c75e30f`. Both Cloud and local assignment counts
were zero before the guest-only switch. Workflow sources predating that merge
must not be selected: their clients do not understand the new configuration.
Retained out-link:
`/var/lib/scherzo-provisioning/linear-transport-system`; system:
`/nix/store/cp92xmwx35akdr266hr7m3jh9fr4qqyf-nixos-system-lima-scherzo-26.11.20260818.0ae2bc1`.
A hardened, read-only `python3 -I -B` probe passed against Linear with `NO_PROXY=*`
and an unrelated ambient HTTPS proxy; selecting an unavailable explicit proxy
failed closed. After activation, native isolated Python using the actual service
environment passed a Linear read, and the actual GitHub client and Git/askpass
read probes still passed. Devenv remains 2.2.2. Runner boot
`rbt_01m23ke1amjk3endrqnf9b023a` is connected with the original credential and
zero local assignments; the Cloud registration remains draining. The host proxy
and lima-dev were not restarted. LIV-2112 has not been dispatched; its review-model
access is operator-confirmed.

## Real task dispatch (2026-09-09)

LIV-2211 succeeded through registered-pool Cloud one-shot run
`run_01m23c8qeea7nb6ajshnjb0bew`, from connected-repository main at
`72582eb09dbf8a141769f3cdaf8e0f784e2c460d`. Input set
`ris_01m23c8hfh77dxqwzgwp3s6x4n` contains the reviewed ticket snapshot. At the
latest observation the run succeeded, PR #1338 is open, and the ticket is In
Review. The runner is drained with no Cloud or local assignments. All seven
artifact members (835,205 bytes) were downloaded and verified after a transient
download failure. Nothing was merged or deployed by this qualification.

Two earlier runs stopped in prepare before the agent, Linear claim, or publication:
`run_01m23bbcj2kxvn3bn1wyxxch0g` and `run_01m23bwpqvjmfpqy25jtm1sfv5`.
Both verified artifacts showed missing Git user.name. An environment-only repair
failed because managed workloads correctly strip GIT_CONFIG_* overrides. The
runner now materializes its ordinary `.gitconfig` at service startup, identifying
commits as `Scherzo Cloud Runner <scherzo-runner@localhost>`. The exact workspace
preparation helper passed a run-scoped check without any GIT_CONFIG override,
and the fresh Cloud run passed preparation and claimed the ticket. This new
guest activation supersedes the historical generation/boot recorded below.

## Publishing-workflow setup (2026-09-09)

This section supersedes the historical qualification notes below. The completion
and migration-ownership fixes are deployed in Cloud release `0.1.2044` at
`21d753c42ae33ea78769ab094facb9dc3122ea3d`. The earlier proxy run completed and
its downloaded artifact has the expected GitHub/Linear success markers. A new
Cloud agent canary also exercised the checkout read tool and both proxy clients;
content-free native tool-call/result observations and the verified response were
captured for `run_01m21p20sdtzgx6rw2jczy6adr`. Agent tool use is now qualified.

For the existing one-shot task LIV-2211, the isolated guest now provides Python,
Nix, Jujutsu, and exactly Devenv 2.2.2 in Runner Serve's PATH. Devenv is pinned by
the separate `scherzo-devenv` flake input, without changing the interactive
Devenv input. The proxy tools package owns the Python and Git entry points:

- Only direct execution of `*/linear_issue_lifecycle.py` gets Linear's public
  placeholder, proxy settings, and public proxy CA bundle. The actual workflow's
  `LinearGraphQLClient` passed a minimal read through this path in a hardened
  systemd job. Ordinary Python and its children retain direct transport.
- The publication helper uses `GH_TOKEN={{scherzo:GITHUB_TOKEN}}`. Git proxying
  is scoped to `https://github.com/scherzo-systems/scherzo-cloud.git`; ordinary
  source checkout remains direct. Git uses the workflow's unmodified askpass
  helper and Basic authentication. The host proxy now validates placeholders
  inside Basic credentials against the same namespace/destination policy before
  substitution and re-encoding. Bearer authentication was rejected by GitHub's
  Git endpoint and is not used.
- `GITHUB_PUBLISH_TOKEN_FILE` names
  `/var/lib/scherzo-cloud/github-publish-placeholder`, a materialized runner-owned
  regular file with mode 0600 containing only that public placeholder. No GitHub
  credential has been copied into the guest or Nix store.

The operator explicitly approved reusing the existing host `GITHUB_TOKEN` and
its broader repository access. GitHub reports `repo` scope and push access to
Scherzo Cloud, no admin/maintain permission there, and no `workflow` scope. This
is not a repository-restricted credential. No second token or host secret edit
was needed. Do not paste tokens into agent prompts or configuration.

The Basic-auth package passed 13 tests, covering substitution, unchanged ordinary
credentials, malformed input, destination rejection, missing secrets, combined
visible/encoded placeholder validation, and secret-safe logging. With operator
approval, only the shared proxy LaunchAgent was restarted using the tested
package; its prior plist is retained for recovery. Neither tunnel nor lima-dev
was restarted. The package is retained by the host's
`~/.local/state/secret-proxy-basic-root` until normal declarative activation.
The actual workflow `GitHubClient` and `run_publication_git`/askpass code passed
read-only repository verification and `ls-remote` under the hardened runner
account. This verifies authentication, not a completed push or PR creation.

The quiescent guest was built and activated without re-enrollment. The existing
checkout's newer pinned NixOS base also updated guest services. No whole-host
activation or `lima-dev` update was made; the separately approved proxy restart
is described above. Active generation:
`/nix/store/m6fwc26xz9hbkn8wlmhmqmrbpj19cvxk-nixos-system-lima-scherzo-26.11.20260818.0ae2bc1`.
Runner boot `rbt_01m239ypwj2gr231f7txf69322` retains the original enrollment.
Hardened smoke checks passed Python 3.14.7, Devenv 2.2.2, Nix 2.34.8, Jujutsu
0.44.0, Python Linear reads, GitHub CLI reads, unprivileged Nix-daemon access,
and placeholder ownership/mode. No failed guest units remain. Before the real task dispatch described above, the runner was drained with
zero assignments and LIV-2211 was still in Backlog. Full workspace validation, Git push/PR creation, and OAuth refresh
remain unqualified.

This is one manually provisioned Cloud runner on gray-area, separate from lima-dev.
Boot, enrollment, outbound connectivity, and guest reboot recovery are verified.
Command-only Cloud execution and verified artifact download passed after correcting
the Linux package and recovering a Coordinator completion stall. Earlier incident
notes below are historical; see the latest qualification result immediately below.
Declarative secret-proxy client wrappers and an independently supervised host
reverse tunnel are deployed. GitHub and Linear reads and automatic tunnel repair
passed under the runner account. Cloud-dispatched proxy workload qualification,
agent harnesses, host-reboot autostart, automatic replacement, and cache retention
remain unqualified.

## Latest qualification: passed (2026-09-08)

The operator-approved Coordinator-only restart at 16:37:31 UTC settled the original
run as `failed`, version 10, at 16:37:32.726964 UTC and released its Cloud assignment.
The exact restart-sensitive failure remains research work in
[LIV-2327](https://linear.app/scherzo-systems/issue/LIV-2327/investigate-coordinator-completion-stalls-cleared-by-restart);
restart recovery is not proof of root cause.

With Cloud and local status both confirming zero assignments and Cloud administration
still draining, the corrected NixOS generation was built, the runner stopped, and
the generation switched. The service reconnected using the same enrolled credential.
Its process executable now resolves to the actual Scherzo binary, not `ld-linux`:
`/nix/store/yf2pz4bg7shbi0skadv5i6mm4pasqfhz-scherzo-cloud-0.30.0/libexec/scherzo-cloud/scherzo-cloud`.
The active system is
`/nix/store/a1c5xnl7zs483bmii4l2kwiajdqcm6zh-nixos-system-lima-scherzo-26.11.20260705.d407951`.

The isolated runner was enabled for one fresh canary, then returned to draining:

- Run: `run_01m20z35rg9shdga91y08ehzfa`, `gray-area-patched-single-step-canary`.
- Workflow: `cli/examples/workflows/single-step.yaml` on `main`, resolved to
  `d68b9da36b66c2dfe4ab9163a906ca4f9b0a8830`. Main advanced since the original
  canary, but the workflow source-closure digest was unchanged.
- Created: 16:54:53.235652 UTC; terminal: 16:55:08.274873 UTC (about 15 seconds).
- Cloud outcome: `succeeded`, version 11, first attempt
  `atm_01m20z3a1kh2d5jk6y957ryxqb`.
- Verified Artifact Set download: `ats_01m20z3pr90a1cvwtemafd9110`, one member,
  2342 bytes. Its `result.json` records a succeeded `greet` command, expected stdout
  `one small step, one successful workflow`, empty stderr, and no truncation.
- The original failed run's Artifact Set also downloaded successfully after recovery:
  `ats_01m20v2pf6jjrwzn1hajfa3kkp`, one member, 2120 bytes.
- Final runner: online, draining, idle; zero Cloud and local assignments; no failed
  guest units; `NRestarts=0`. New runner boot ID:
  `rbt_01m20z2q1ar4cs1ap3bhxsrbxk`.

This qualifies the command-only path, not agent workloads or secret-proxy transport.
The updated package has not yet been retested through another guest reboot.
No changes were made to lima-dev or existing project routing.

## Configured secret-proxy transport (2026-09-08)

- `modules.dev.secret-proxy.additionalLimaInstances = [ "lima-scherzo" ]` on
  gray-area creates a separate launchd tunnel supervisor, preserving the existing
  primary lima-dev tunnel label and settings.
- `packages/linear-cli.nix` pins Linear CLI 2.0.0 and release hashes, using the
  Scherzo Cloud repository's Deno-payload-preserving Linux packaging.
- `packages/scherzo-proxy-tools.nix` installs `gh` and `linear` wrappers in the guest
  system and Runner Serve PATH. Only these clients receive proxy settings, a CA
  bundle containing the public host proxy CA, and Scherzo-namespace placeholders.
  No real credential or CA private key enters the guest or Nix store. The public
  CA matched the running host proxy before deployment.
- Runner Serve and source checkout keep direct transport and normal TLS trust;
  there are no global proxy settings or globally installed interception CA.

After confirming Cloud and local quiescence while draining, the guest was switched
to `/nix/store/5i3xl6l4bf5xymrpply68af37jqj3n6v-nixos-system-lima-scherzo-26.11.20260705.d407951`.
The enrolled service restarted normally without re-enrollment.

The host service configuration was evaluated from its updated checkout. Only the
new `org.nixos.secret-proxy-tunnel-lima-scherzo` LaunchAgent was bootstrapped from
that evaluated configuration, at
`~/Library/LaunchAgents/org.nixos.secret-proxy-tunnel-lima-scherzo.plist`.
Its script is retained by `~/.local/state/scherzo-proxy-tunnel-root` until normal
whole-host activation provides a system-generation root. This targeted activation
avoided unrelated host changes and restarting the existing proxy/lima-dev tunnel.
It uses the logged-in user's launchd domain, not a boot-time LaunchDaemon; host
reboot/autologin behavior is not qualified.

Removing the new reverse forward and waiting 20 seconds proved automatic repair:
the new supervisor stayed running and both installed wrappers succeeded under a
hardened transient systemd job as `scherzo-runner`, with `SSH_AUTH_SOCK`, proxy,
CA, and credential variables explicitly unset before invoking the wrappers.
GitHub returned `scherzo-systems/scherzo-cloud`; Linear read LIV-2327 without
attachment downloads. No failed guest units were present afterward.

The earlier run-scoped probes below are historical evidence. They are no longer
needed by the installed client wrappers. A Cloud-dispatched workflow has not yet
exercised these wrappers; that is the next qualification step.

## Initial secret-proxy smoke test (2026-09-08)

Reused gray-area's existing service-account-backed proxy without reading or copying
credential values. Added a separate reverse forward through lima-scherzo's Lima
SSH control connection: guest `127.0.0.1:17329` to host `127.0.0.1:17329`.
The existing lima-dev forward and proxy service were not changed or restarted.
Only the public proxy CA was copied to the new guest.

Three transient systemd jobs ran as `scherzo-runner`, with `NoNewPrivileges`,
`PrivateTmp`, `ProtectHome`, and `ProtectSystem=strict`. They used an isolated home
under `/var/lib/scherzo-cloud/proxy-qualification`, explicit proxy/CA settings,
placeholder credentials `{{scherzo:GITHUB_TOKEN}}` and
`{{scherzo:LINEAR_API_KEY}}`, and no `SSH_AUTH_SOCK`:

1. GitHub CLI 2.96.0 read `repos/scherzo-systems/scherzo-cloud`; Linear CLI 2.0.0
   read LIV-2327 with `--json --no-download`. Both succeeded; the returned Linear
   identifier was verified.
2. With only the new VM's reverse forward removed, both clients exited 1.
3. After explicitly restoring that forward, both read-only calls succeeded again.

No provider mutations were performed. The Cloud runner's environment was not
changed; its control-plane connection remains direct and the runner stays drained.

This is service-account/network qualification, **not a Cloud-dispatched workflow
result**. The tunnel was established and restored manually, not by an autonomous
supervisor; automatic bridge recovery and VM reboot recovery remain untested.
The client packages, CA bundle, and probe scripts are run-scoped guest state, not
part of the declarative NixOS runner configuration. Next steps are durable,
workload-scoped wiring and a reviewed published command workflow for Cloud
qualification. Do not depend on these temporary files for replacement VMs.

## Subscription authentication qualification (2026-09-08)

Pi 0.84.4 was built from the Scherzo Cloud repository's pinned `nix/pi.nix` and
retained at `/nix/var/nix/gcroots/scherzo-pi-qualification`. This is a qualification
installation, not yet part of the declarative runner PATH.

The operator completed a separate guest login. With permission, its auth file was
moved (not copied) from the guest login user's home to
`/var/lib/scherzo-cloud/.pi/agent/auth.json`, owned by `scherzo-runner`, mode 0600.
Credential values were not inspected. Do not clone or snapshot this authenticated VM.

A hardened transient systemd job as `scherzo-runner`, with a clean environment,
no API key, proxy, SSH agent, tools, extensions, or session persistence, successfully
called `openai-codex/gpt-5.6-sol` and returned `subscription-auth-ok` (exit 0).
The catalog also listed `gpt-5.4-mini` and `gpt-5.4`, but both were rejected by
Codex as unsupported for this ChatGPT account. Use the actually qualified model,
not catalog presence alone, for the next smoke test.

This verifies unattended subscription access, not refresh-token renewal, agent tool
execution, or Cloud dispatch. Auth remains mutable guest-local state and replacement
requires another login. A host-owned OAuth lifecycle is deferred future work.

## Cloud subscription-agent qualification: passed (2026-09-08)

`packages/pi.nix` now pins Pi 0.84.4 declaratively in both the guest system and
Runner Serve PATH. The service explicitly sets `PI_CODING_AGENT_DIR` to the
private, mutable `/var/lib/scherzo-cloud/.pi/agent`; no auth file enters the Nix
configuration. The earlier standalone Pi qualification GC root is not required
by the service. After checking quiescence, the guest was switched to
`/nix/store/jpzh6chbai08qpk5v0jdgpcb2zkw0x6w-nixos-system-lima-scherzo-26.11.20260705.d407951`.

The existing published `cli/examples/workflows/agent-basic.yaml` was dispatched
through the isolated Cloud project. It asks for 17 + 25 and instructs the agent
not to use tools, using `openai-codex/gpt-5.6-luna` with low thinking.

- Run: `run_01m214qjbttsqdk4ates8gnfxc`.
- Source: `342a2de20ff6fee7cbcd2b3b1ec89e2adaf8d0e6` on main.
- Attempt: `atm_01m214qq2p85gtpc9w2dqpmzma`.
- Created 18:33:24.822087 UTC; terminal 18:33:39.549540 UTC.
- Cloud outcome: succeeded, version 11, first attempt.
- Verified Artifact Set: `ats_01m214r2p2hk7cexh72rt6g431`, two members,
  2166 bytes. The downloaded exported response is exactly `42`.
- Final runner: online, draining, zero Cloud and local assignments. Enrollment
  credential unchanged; runner boot ID `rbt_01m214hv4k2dee9y0z8nprgp9t`.

This qualifies basic Cloud agent execution with guest-local subscription OAuth.
It does not qualify refresh renewal, agent tool use, implementation/publication
workflows, or the Cloud-dispatched GitHub/Linear checks tracked in LIV-2329.
The Linear trigger's exact-ticket routing restriction also remains unchanged.

## Latest state: proxy Cloud qualification blocked (2026-09-08)

LIV-2329 implementation is published in Scherzo Cloud PR #1315, commit
`df3faf241962ab121eb32ea4594206bdbd2579e3`. Local workflow validation, seven
success/failure cases, and selected pre-publication repository checks passed.
`jq` was added to the guest system/service PATH for strict response validation.
The deployed guest generation is
`/nix/store/0ff67jmprvs32dmia0qch5jpnldam44x-nixos-system-lima-scherzo-26.11.20260705.d407951`.

Cloud dispatched `.scherzo/cloud/proxy-qualification.yaml` from branch
`bromanko/liv-2329-proxy-qualification` as run `run_01m215pwf77swh83mrkchekr8h`.
Its retained terminal input reports **succeeded**, but the Coordinator repeatedly
fails reduction with `input_reduction_database_failure`. Cloud remains running,
version 14, last updated 18:50:44.038284 UTC. The three-minute wait timed out;
artifact download is unavailable. This is not an end-to-end pass.

- Attempt: `atm_01m215q057n4qy669ma7dz548x`.
- Assignment: `asn_01m215q0afn5vgmd22hk5fsrns`.
- Pending completion: `cmd_01m215qf0x0xjgf1hthtqersqa`.
- Artifact Set: `ats_01m215qdmhkdmkpf01hmxpctfm`.
- Runner: online and draining; Cloud assignments 1, local assignments 0.

**Do not replace/update the guest as though it were quiescent.** No shared service
restart, resubmission, or database mutation was performed. The recurrence evidence
was added to LIV-2327, LIV-2329, and PR #1315. LIV-2329 remains incomplete; PR
review/CI/merge are separate. Earlier successful qualifications below/above are
historical results, not evidence that this pending run has settled.

## Configuration

- `configs/lima/scherzo.yaml`: VZ ARM64 VM, 3 CPUs, 8 GiB RAM, 100 GiB disk.
- `hosts/nixos/aarch64-linux/lima-scherzo/default.nix`: NixOS and hardened systemd service.
- `packages/scherzo-cloud.nix`: CLI/Runner Serve 0.30.0, with release archive hashes.
- `configs/lima/provision-scherzo`: apply this checkout to the unenrolled VM.

No host mounts, forwarded SSH agents, or application port forwards are configured.
Enrollment state lives only in the guest under `/var/lib/scherzo-cloud`, mode 0700.
Never clone or snapshot this VM after enrollment. The non-secret runner config must
be a regular file, not a Nix store symlink; enrollment checks this explicitly.

## Create and provision

On gray-area, from the intended nix-config checkout:

```sh
limactl validate configs/lima/scherzo.yaml
limactl start --name=lima-scherzo --tty=false configs/lima/scherzo.yaml
./configs/lima/provision-scherzo
```

Provisioning uses the checkout's existing flake.lock without changing it, including
tracked modifications and non-ignored new files. Review `git status` first. It does
not fetch a floating nix-config branch. The source archive excludes AppleDouble
metadata and ignored files; never place plaintext secrets in the source tree.
Provisioning refuses an already-enrolled VM: routine updates require a separate
reviewed drain-and-update procedure.

The first switch from the base image encountered D-Bus reload failures. The system
closure and bootloader were installed; stopping/starting only lima-scherzo and then
rerunning provisioning succeeded. Do not treat an arbitrary provisioning failure
as this same condition: inspect `/tmp/lima-scherzo-provision.log` if output was
redirected there, and verify system and user failed units before enrollment.

## Enroll

Use the same CLI release as the guest, from an authenticated operator machine.
Build it without installing it globally from this nix-config checkout:

```sh
cli=$(nix build --no-link --no-write-lock-file --print-out-paths path:.#scherzo-cloud)/bin/scherzo-cloud
"$cli" auth status
```

The existing prototype pool and registration below are already created and enrolled.
Do not rerun creation against them. For a new experiment, choose unused names and
an isolated pool that no project targets:

```sh
"$cli" runner pool create ORGANIZATION --name POOL
set -o pipefail
"$cli" runner create ORGANIZATION --pool POOL --name RUNNER --activation-file - |
  ssh gray-area 'limactl shell lima-scherzo sudo -H -u scherzo-runner /run/current-system/sw/bin/scherzo-cloud runner enroll --activation-file - --config /etc/scherzo/runner.json'
ssh gray-area 'limactl shell lima-scherzo sudo systemctl start scherzo-runner.service'
```

Activation passes directly through stdin, never through command arguments or a
second file. If registration succeeds but enrollment fails before staging, inspect
the registration and issue a replacement activation for that same ID with
`runner activation create ORGANIZATION RUNNER_ID --activation-file -`; do not create
a duplicate registration. If an enrollment journal was staged, follow the CLI's
`--resume` recovery procedure instead of replacing or deleting protected state.

## Inspect

```sh
ssh gray-area 'limactl shell lima-scherzo sudo -H -u scherzo-runner /run/current-system/sw/bin/scherzo-cloud runner status --config /etc/scherzo/runner.json'
"$cli" runner show scherzo-systems rnr_01m20te3hbae619p5npmp45t5q
ssh gray-area 'limactl shell lima-scherzo systemctl is-active scherzo-runner'
```

The prototype is deliberately left **draining** and online. Following the command
canary, local status has zero assignments but Cloud still reports one current
assignment. Do not restart, destroy, or submit additional work merely to clear this
discrepancy; preserve it for diagnosis. The isolated gray-area-canary project now
routes to this pool; existing project routing was not changed.

## Reboot and eventual teardown

Drain first and verify both Cloud and local status have no current assignments.
For the guest reboot check, use `limactl stop lima-scherzo` followed by
`limactl start --tty=false lima-scherzo` on gray-area. Verify a new local runner boot
ID, the same credential ID, and independently online Cloud status.

Destruction is a separate explicit operation, not scheduled cleanup. After drain
and quiescence, stop the guest and disable/revoke its Cloud authority before deleting
the Lima instance. Remove the quiescent Cloud registration separately if desired;
Cloud deletion never cleans host files. Do not delete the pool while it is in use.
Never target lima-dev or blindly kill a busy runner to meet a rotation deadline.

## Observed evidence (2026-09-08)

- Host checkout base: `0e1df92` plus the prototype files; its existing modification
  to `packages/lima-tmux-shell.nix` was preserved. The author's local checkout base
  is `bf265ce`; the NixOS configuration also evaluated there without lock changes.
- Organization: `scherzo-systems` (`org_01m1h8cdyjkqpt667y18340bq7`).
- Pool: `gray-area-prototype` (`rpl_01m20te377vxqx6p6e2kgb0jms`).
- Runner: `gray-area-lima-scherzo` (`rnr_01m20te3hbae619p5npmp45t5q`).
- Runner Serve 0.30.0 connected and advertised protocol 1.
- Reboot changed the runner boot ID, retained its credential, and reconnected.
- No failed system services; Runner Serve active with zero automatic restarts.
- Approximately 7.3 GiB allocated on macOS, 7.1 GiB used in the guest, 50 GiB free.
- Idle guest memory approximately 292 MiB used; this is not build-workload sizing.
- lima-dev remained running and was not reconfigured or restarted.

No macOS host reboot was tested.

## Command canary (2026-09-08)

Created a separate project `gray-area-canary`
(`prj_01m20v1zzp0kp4b93kynhmxj9p`) using the existing Scherzo Cloud repository
connection and the prototype pool. No harness or provider credential was installed.

Submitted the unchanged `cli/examples/workflows/single-step.yaml` from published
`main`, which runs only `sh -c` with a shell-builtin print command:

```sh
"$cli" run create scherzo-systems \
  --project-id prj_01m20v1zzp0kp4b93kynhmxj9p \
  --workflow-path cli/examples/workflows/single-step.yaml \
  --source-branch main --display-name gray-area-single-step-canary --json
```

- Run: `run_01m20v29jy2gzdk6ckgcg7kbc1`.
- Resolved commit: `478d64d068cd6d4d43cd09a1b2188ca18141affd`.
- Assignment: `asn_01m20v2cqyybz9g7x9km3qareh`.
- Workflow admission succeeded in approximately 4.7 seconds.
- Runner received execution authority at 15:44:38 UTC and emitted transitions.
- Cloud sent `artifact_result_confirmation` at 15:44:40 UTC.
- Runner sent `execution_finished`, sequence 17, message
  `rmsg_01m20v2r2rcwexvfcfen1zhzfs` at 15:44:40.536 UTC.
- Cloud acknowledged that exact message/sequence at 15:44:40.605 UTC.
- `run wait --timeout 3m` timed out. Cloud continued to show `running`, version 9,
  and one current assignment, while local Runner Serve showed zero assignments.
- The public Artifact Set download returned not found. No result was downloaded,
  so neither the command exit outcome nor complete artifact delivery is verified.
- Runner was returned to draining without restarting or clearing its state.

This is a failed end-to-end canary with useful evidence of source preparation and
execution transport, not a successful workflow result. Investigate Cloud completion
processing before enabling more work or adding harnesses. Protocol acknowledgement
alone does not prove the terminal observation was applied to the run projection.

## Debugging findings (2026-09-08)

### Confirmed runner packaging defect, corrected but not deployed to the service

The stored canary outcome is `failed` with `command_launch_failed`. The command
never successfully launched. The original Linux package invoked `ld-linux`
explicitly, so both `version --json` and `/proc/<runner-pid>/exe` identified the
loader instead of the Scherzo executable. Scherzo's child-process guard uses
`current_exe()` to re-execute itself, which this packaging broke.

`packages/scherzo-cloud.nix` now uses `autoPatchelfHook` to patch the ELF interpreter
and RPATH, and wraps the Scherzo executable directly. Its install check runs a
minimal command workflow, not just a version probe. Linux and Darwin package
builds and their command-workflow install checks passed. In an isolated local
workflow on lima-scherzo, the old package reproduced `command_launch_failed` and
the corrected package succeeded with exit 0. The corrected binary reports its
own libexec path as `executablePath`.

The enrolled systemd service still uses the old package. Do not use this local
A/B result as Cloud end-to-end success, or rebuild the enrolled VM while Cloud
still considers the canary assigned.

### Coordinator completion failure remains under investigation

Coordinator diagnostics join the runner's terminal message to input
`cmd_01m20v2r2swz04w919wrh05ja1`. The deployed Coordinator repeatedly reports
`input_reduction_database_failure`, with no applied state transition. Its release
is `0.1.1939+rev-ee240c3a1ca78772ecb81f697ead30e9c9c3eb3e`, started September 6.
The runtime database role and artifact-retention setting match the configuration.

Read-only checks found the Artifact Set prepared, with a matching verified result
digest. The inspected terminal SQL plans and relevant privileges were valid.
Copied-row tests and subsequent bounded rollback-only SQL diagnostics passed the
terminal updates and deferred constraints. No diagnostic transaction committed.

A separate ephemeral Erlang process then loaded the deployed Coordinator modules,
exposed private functions only inside that diagnostic process, and used the actual
runtime database role. It claimed the same pending input, loaded the assignment,
checked semantic replay, invoked `reduce_new_input` with the production seed
factory, and checked deferred constraints. It returned `Applied`; the enclosing
transaction deliberately returned an error to force rollback. The running service
was not modified, hot-patched, or restarted.

This narrows the remaining problem toward process- or connection-local state but
does not establish the exact cause. The live Coordinator still fails and the run
remains `running`, version 9. Existing telemetry collapses PostgreSQL, argument,
and result-decoding failures into the same database-failure classification.
A controlled shared Coordinator restart needs operator approval; it is a recovery
experiment, not proof of root cause. Better bounded query-error diagnostics may
be needed if the issue recurs.

The local Coordinator integration suite also passed. No production schema,
credential, run state, or service configuration was changed by these diagnostics.
Temporary database objects and diagnostic processes were discarded, and the
personal Tailscale profile was restored after control-plane inspection.
