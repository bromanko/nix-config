{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
{
  imports = [ ./hardware-configuration.nix ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  # Network configuration
  networking.useDHCP = false;
  networking.interfaces.enp0s1.useDHCP = true;
  networking.hostName = "lima-dev";

  # This is a VM so we rely upon the host firewall for external access
  # but we need to allow internal services
  networking.firewall = {
    enable = true;
    allowedTCPPorts = [ 8118 ]; # Privoxy default port
  };

  # Don't require password for sudo
  security.sudo.wheelNeedsPassword = false;

  # Enable SSH for remote access
  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = true;
      PermitRootLogin = "yes";
    };
  };

  # Privoxy configuration
  services.privoxy = {
    enable = true;
    settings = {
      listen-address = "0.0.0.0:8118";
      actionsfile = [
        "/etc/privoxy/match-all.action"
        "/var/lib/privoxy/user.action"
      ];
      filterfile = [
        "default.filter"
      ];
      # Allow editing the domain list without rebuilds
      confdir = "/var/lib/privoxy";
    };
  };

  # Create directory for user-editable Privoxy config
  systemd.tmpfiles.rules = [
    "d /var/lib/privoxy 0755 privoxy privoxy -"
    "f /var/lib/privoxy/user.action 0644 privoxy privoxy -"
  ];

  # Set up user-editable action file with allow list
  environment.etc."privoxy/user.action.template" = {
    text = ''
      # User-editable domain allow list
      # This file can be edited without rebuilding the Nix configuration
      # Copy this template to /var/lib/privoxy/user.action and edit as needed
      #
      # Format: Add allowed domains like this:
      # { +forward-override{forward .} }
      # .example.com
      # .github.com
      # .nixos.org
      #
      # Then restart privoxy: sudo systemctl restart privoxy

      # Default: block everything
      { +block{Blocked by default policy} }
      /

      # Allow local addresses
      { -block }
      127.0.0.0/8
      10.0.0.0/8
      192.168.0.0/16
      172.16.0.0/12

      # Add your allowed domains below by copying this file to /var/lib/privoxy/user.action
      # and editing it. Example entries:
      #
      # { -block }
      # .example.com
      # .github.com
    '';
    mode = "0644";
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Los_Angeles";

  users.mutableUsers = false;

  # Integration with existing home-manager config
  home-manager.users."${config.user.name}" = 
    import ../../aarch64-linux/lima-dev/default.nix;

  modules = {
    nix = {
      enable = true;
      dev.enable = true;
    };
    shell = {
      commonPkgs.enable = true;
      openssh.enable = true;
      fish.enable = true;
      bat.enable = true;
      git.enable = true;
      jujutsu.enable = true;
      starship.enable = true;
      fzf.enable = true;
      direnv.enable = true;
      exa.enable = true;
      fd.enable = true;
    };
    dev = {
      elixir.enable = true;
      idea.enable = true;
      psql.enable = true;
      nodejs.enable = true;
      codex.enable = true;
      claude-code.enable = true;
    };
    editor = {
      default = "nvim";
      neovim.enable = true;
    };
  };

  system.stateVersion = "24.05";
}