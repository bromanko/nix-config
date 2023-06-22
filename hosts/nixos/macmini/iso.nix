{ config, lib, pkgs, ... }:

{
  imports = [
    <nixpkgs/nixos/modules/installer/cd-dvd/installation-cd-minimal.nix>
    <nixpkgs/nixos/modules/installer/cd-dvd/channel.nix>
  ];

  nixpkgs.config.allowUnfree = true;
  boot.kernelModules = [ "wl" ];
  boot.externalModulePackages = [ config.boot.kernelPakcages.broadcom_sta ];
  boot.blacklistedKernelModules = [ "b43" "bcma" ];
  networking.wireless.enable = false;

  # Need to use iwd due to a bug with Broadcom adapters
  # in version 2.10 of wpa_supplicant.
  networking.wireless.iwd.enable = true;
}
