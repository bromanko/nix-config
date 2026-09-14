# Second gray-area runner

Current sizing: 3 CPUs, 8 GiB RAM, 100 GiB disk and 4 GiB swap; CLI 0.35.1,
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
The non-secret `pi-models.json` includes the temporary Astra catalog entry from
the operator's Home Manager configuration. It does not supply credentials.
Before ticket dispatch, qualify actual model access and Cloud agent execution.
Two heavy concurrent implementations and OAuth refresh remain unqualified.

`lima-dev` is stopped, not deleted; Docker has 4 GiB configured. Do not restart
lima-dev alongside both runners without reassessing the 24-GiB host's memory.
