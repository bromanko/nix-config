{
  config,
  lib,
  pkgs,
  ...
}:

{
  boot.kernelModules = [ "wl" ];
  boot.extraModulePackages = [ config.boot.kernelPackages.broadcom_sta ];
  boot.blacklistedKernelModules = [
    "b43"
    "bcma"
  ];
  networking.wireless.enable = false;

  # Need to use iwd due to a bug with Broadcom adapters
  # in version 2.10 of wpa_supplicant.
  networking.wireless.iwd.enable = true;
}
