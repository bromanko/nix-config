{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  imports = [ ./hardware-configuration.nix ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

  time.timeZone = "America/Los_Angeles";

  # The global useDHCP flag is deprecated, therefore explicitly set to false here.
  # Per-interface useDHCP will be mandatory in the future, so this generated config
  # replicates the default behaviour.
  networking.useDHCP = false;
  networking.interfaces.ens33.useDHCP = true;

  # We expect to run the VM on hidpi machines.
  hardware.video.hidpi.enable = true;

  # This is a vm so we rely upon the host firewall
  networking.firewall.enable = false;

  # Don't require password for sudo
  security.sudo.wheelNeedsPassword = false;

  virtualisation = { vmware.guest.enable = true; };

  i18n.defaultLocale = "en_US.UTF-8";

  # shared folder with host
  # fileSystems."/host" = {
  #   fsType = "fuse./run/current-system/sw/bin/vmgfs-fuse";
  #   device = ".host:/";
  #   options = [
  #     "umask=22"
  #     "uid=1000"
  #     "gid=1000"
  #     "allow_other"
  #     "auto_unmount"
  #     "defaults"
  #   ];
  # };

  users.mutableUsers = false;

  # todo make this a module
  services.openssh = {
    enable = true;
    passwordAuthentication = true;
    permitRootLogin = "yes";
  };

  # todo make this a module
  programs.ssh = {
    startAgent = true;
    extraConfig = ''
      Host github.com
        IdentitiesOnly yes
        AddKeysToAgent yes
        IdentityFile ~/.ssh/github
    '';
  };

  services.xserver = {
    enable = true;
    layout = "us";
    dpi = 220;

    desktopManager = {
      xterm.enable = false;
      wallpaper.mode = "scale";
    };

    displayManager = {
      defaultSession = "none+i3";
      lightdm.enable = true;
      autoLogin.enable = true;
      autoLogin.user = config.user.name;

      sessionCommands = ''
        ${pkgs.xlibs.xset}/bin/xset r rate 200 40
      '';
    };

    windowManager = { i3 = { enable = true; }; };

    videoDrivers = [ "vmware" "vesa" "modesetting" ];
  };

  services.randr = {
    enable = true;
  };

  home-manager.users."${config.user.name}".home = {
    file.".config/i3/config".source = ../../../configs/i3/config;
  };

  modules = {
    shell = {
      commonPkgs.enable = true;
      zsh.enable = true;
      bat.enable = true;
      git.enable = true;
      starship.enable = true;
      fzf.enable = true;
      direnv.enable = true;
      exa.enable = true;
      fd.enable = true;
    };
    desktop = {
      fonts.enable = true;
      #   apps = {
      #     espanso.enable = true;
      #   };
    };
    dev = {
      elixir.enable = true;
      idea.enable = true;
      psql.enable = true;
      # docker.enable = true;
      nix.enable = true;
      nodejs.enable = true;
    };
    term = { kitty.enable = true; };
    editor = {
      neovim.enable = true;
      emacs.enable = true;
    };
  };

  # This value determines the NixOS release from which the default
  # settings for stateful data, like file locations and database versions
  # on your system were taken. It‘s perfectly fine and recommended to leave
  # this value at the release version of the first install of this system.
  # Before changing this value read the documentation for this option
  # (e.g. man configuration.nix or on https://nixos.org/nixos/options.html).
  system.stateVersion = "21.05"; # Did you read the comment?
}
