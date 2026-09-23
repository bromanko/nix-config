# Second gray-area runner

Current sizing: 3 CPUs, 8 GiB RAM, 100 GiB disk and 4 GiB swap; CLI 0.41.0,
Pi 0.85.0, independent OAuth completed. See [the dual-runner trial status](README-sizing.md)
for the boot override and remaining qualification prerequisites. Provisioning notes
below describe the original setup.

Provisioned 2026-09-13 as `lima-scherzo-2`: 2 CPUs, 8 GiB RAM, 60 GiB disk,
2 GiB guest swap, CLI 0.35.0 and Pi 0.85.0. It imports the first runner's
hardened configuration but has an independent disk, enrollment, work root,
control socket and host proxy tunnel. No authenticated VM was cloned.

The existing `scherzo.yaml` template supports creation; the checked provisioning
script now accepts `lima-scherzo-2` explicitly. Its default remains `lima-scherzo`.
Never invoke provisioning against an enrolled VM; drain and inspect both Cloud
and local assignments before updates.

The fresh image had no swap; initial Nix provisioning was OOM-killed. Installing
the planned 2 GiB swap and importing only the first VM's immutable system Nix
closure avoided rebuilding dependencies. A reboot resolved the base-image
hostname/Home Manager and D-Bus activation transition. Final provisioning passed
with no failed services. The first VM's running LIV-2323 was not restarted.

Cloud registration: `rnr_01m2eg19qm5fj56sghkyktwhhw`, name
`gray-area-lima-scherzo-2`, pool `gray-area-prototype`. Enrollment was streamed
directly from the operator CLI, not saved in source or cloned from another VM.
The runner is connected and draining with zero restarts.

JSON command canary `run_01m2eg23t8abv3t4de2vs8btqs` succeeded and its Artifact Set
was downloaded and verified. Proxy-backed GitHub and Linear reads passed.
The separate `org.nixos.secret-proxy-tunnel-lima-scherzo-2` LaunchAgent was
activated without restarting the shared proxy or first VM's tunnel. Its Nix
script is rooted at `~/.local/state/secret-proxy-tunnel-mini2-root` on gray-area.

## Initial subscription login (subsequently completed)

This runner needs its own OAuth login; never copy the first VM's `auth.json`.
From a terminal on gray-area:

```sh
limactl shell lima-scherzo-2 sudo -H -u scherzo-runner env \
  HOME=/var/lib/scherzo-cloud \
  PI_CODING_AGENT_DIR=/var/lib/scherzo-cloud/.pi/agent \
  /run/current-system/sw/bin/pi
```

Use `/login`, select OpenAI Codex, complete browser authorization, then exit Pi.
The initial configuration installed a temporary, non-secret Astra entry in
`/var/lib/scherzo-cloud/.pi/agent/models.json`. On 2026-09-23, Pi's catalog
was refreshed independently on both runners. An isolated catalog-only check
found `openai-codex/gpt-6-astra` on both without `models.json`. Both obsolete
runner-owned files were removed while drained, and the second guest activated
`/nix/store/7g71fs7gb6v51gwmbmz2gc53vcpx4yv9-nixos-system-lima-scherzo-2-26.11.20260818.0ae2bc1`
without the declarative override. Its closure removed only the temporary
`scherzo-pi-models.json` entry. Both guests now use Pi's built-in and refreshed
provider catalogs; no credentials were copied. A catalog row is not proof of
live model access: qualify actual model calls and Cloud agent execution before
ticket dispatch. Two heavy concurrent implementations and OAuth refresh remain
unqualified.

`lima-dev` is stopped, not deleted; Docker has 4 GiB configured. Do not restart
lima-dev alongside both runners without reassessing the 24-GiB host's memory.
