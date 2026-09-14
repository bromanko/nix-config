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

