## Disk-backed temporary storage (2026-09-15)

Both runners now use disk-backed ext4 `/tmp`, including Runner Serve's
`PrivateTmp` namespace. `/run` remains tmpfs. This avoids the 3.9-GiB tmpfs
limit that stopped LIV-2353's cold isolated CLI build. Both guests were updated
and rebooted one at a time after confirming Cloud and local idle/draining state;
their enrolled credentials, retained work and existing system closures remain
unchanged. No host, proxy, lima-dev or unrelated NixOS rollout was performed.

The shared `hosts/nixos/aarch64-linux/lima-scherzo/default.nix` now declares
`boot.tmp.useTmpfs = false`, inherited by the second runner. At maintenance time,
the checkout's `flake.lock` conflict and unrelated pending changes prevented a
safe full closure deployment. The live change therefore uses a persistent mask:
`/etc/systemd/system.control/tmp.mount -> /dev/null` on each guest. Remove only
this mask after deliberately deploying the matching declarative closure; do not
unmask it while the old closure still enables tmpfs. The mask survived both
reboots. Existing daily systemd-tmpfiles cleanup retains its 10-day `/tmp` age
policy and boot cleanup remains configured; runner work under `/var/lib` is not
part of that cleanup.

Receipts and the cold isolated CLI build qualification are retained under
`/var/lib/scherzo-cloud/recovery/disk-tmp-20260915/`. Qualification status is
recorded in `cli-check-exit` and `cli-check.log` on the first runner. The cold
public CLI source-boundary check passed (exit 0) using ordinary `/tmp` inside a
private systemd namespace, including the isolated Rust tests and release build.
Its log includes non-fatal cleanup warnings for read-only test fixtures. Both
runners remain draining, online and idle; no ticket was dispatched by this
maintenance. The lock conflict was subsequently resolved without advancing any
input pins. Both runner system derivations and the gray-area Darwin derivation
now evaluate successfully; both runners resolve disk-backed `/tmp` and 4-GiB
swap. Formatting, shell syntax and Lima template validation passed. These are
evaluation checks, not a deployment: the live masks remain until an explicit
quiescent activation of the matching closures.

## Dual-runner sizing trial (2026-09-14)

Both existing runner VMs now have **3 CPUs, 8 GiB RAM, 100 GiB disk and
4 GiB guest swap**. They were resized in place, one at a time, and reboot-tested.
The NixOS system closures, CLI 0.35.1, Pi 0.85.0, independent enrollment/OAuth,
and retained assignment directories were preserved. No provisioning, workspace
cleanup or authenticated cloning occurred. `lima-dev` remains stopped and Docker
remains configured for 4 GiB on the 24-GiB host.

The template and shared NixOS swap declaration now reflect these sizes. To avoid
an unrelated NixOS rollout, the existing swap file was replaced only after its
4-GiB replacement was allocated, formatted and the old swap taken offline; its
UUID was retained. The old closure otherwise recreates swap at 2 GiB on boot.
A persistent, tested guard in
`/etc/systemd/system.control/mkswap-swapfile.service.d/90-operator-resize.conf`
prevents that recreation and verifies the existing 4-GiB file. Remove this exact
drop-in after deploying a closure with the updated `size = 4096` declaration.

Both runners are connected and **draining**, with zero local assignments. The
second runner's Cloud activity still projects the old LIV-2292 assignment despite
its confirmed OOM interruption and manual recovery PR #1479; this stale assignment
must be reconciled before new dispatch. Two simultaneous workflows remain
unqualified. Before the trial, enforce one heavyweight check at a time per VM and
single-job Cargo even in isolated Cargo homes. Merely increasing CPU count does
not implement these limits, and the workflow must explicitly support CI deferral.

Resize receipts/config backups are on gray-area under
`~/.local/state/scherzo-operator/resize-dual-20260914/`; guest preservation receipts
are under `/var/lib/scherzo-cloud/recovery/resize-dual-20260914/`.

