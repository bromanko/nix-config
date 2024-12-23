{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
with lib.my;
{
  imports = [ ./hardware-configuration.nix ];

  boot = {
    loader = {
      efi.canTouchEfiVariables = true;
      systemd-boot.enable = true;
    };
  };

  # The default governor constantly runs all cores
  # at max frequency. Schedutil will run at a lower
  # frequency and boost when needed
  powerManagement.cpuFreqGovernor = "schedutil";

  # Using iwd since there is a bug with wpa_supplicant 2.10
  # with Broadcom chips
  networking = {
    wireless.iwd.enable = true;
    networkmanager = {
      enable = true;
      wifi.backend = "iwd";
    };
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Los_Angeles";

  services.openssh = {
    enable = true;
  };

  modules = {
    shell = {
      commonPkgs.enable = true;
      bat.enable = true;
      git.enable = true;
      fish.enable = true;
      starship.enable = true;
      fzf.enable = true;
      direnv.enable = true;
      exa.enable = true;
      fd.enable = true;
    };
    desktop = {
      fonts.enable = true;
    };
    dev = {
      nix.enable = true;
    };
    editor = {
      neovim.enable = true;
      emacs.enable = true;
    };
    tailscale.enable = true;
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It's perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "24.11"; # Did you read the comment?
}
