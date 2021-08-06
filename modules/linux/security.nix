{ config, lib, pkgs, ... }:

{
  # tmpfs = /tmp is mounted in ram. Doing so makes temp file management speedy
  # on ssd systems, and volatile! Because it's wiped on reboot.
  boot.tmpOnTmpfs = lib.mkDefault true;
  # If not using tmpfs, which is naturally purged on reboot, we must clean it
  # /tmp ourselves. /tmp should be volatile storage!
  boot.cleanTmpDir = lib.mkDefault (!config.boot.tmpOnTmpfs);

  # Change me later!
  user.initialPassword = "nixos";
  users.users.root.initialPassword = "nixos";
}
