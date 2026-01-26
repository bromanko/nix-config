{
  config,
  lib,
  pkgs,
  ...
}:

{
  # tmpfs = /tmp is mounted in ram. Doing so makes temp file management speedy
  # on ssd systems, and volatile! Because it's wiped on reboot.
  boot.tmp.useTmpfs = lib.mkDefault true;
  # If not using tmpfs, which is naturally purged on reboot, we must clean it
  # /tmp ourselves. /tmp should be volatile storage!
  boot.tmp.cleanOnBoot = lib.mkDefault (!config.boot.tmp.useTmpfs);

  # Change me later!
  user.initialPassword = "nixos";
  users.users.root.initialPassword = "nixos";
}
