{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  dpi = 163;
in
{
  imports = [ ./hardware-configuration.nix ];

  # Use the systemd-boot EFI boot loader.
  boot.loader.systemd-boot.enable = true;
  boot.loader.efi.canTouchEfiVariables = true;

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

  virtualisation = {
    vmware.guest.enable = true;
  };

  i18n.defaultLocale = "en_US.UTF-8";
  time.timeZone = "America/Los_Angeles";

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

  services.openssh = {
    enable = true;
    passwordAuthentication = true;
    permitRootLogin = "yes";
  };

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
    dpi = dpi;

    desktopManager = {
      xterm.enable = false;
      wallpaper.mode = "fill";
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

    windowManager = {
      i3 = {
        enable = true;
        package = pkgs.i3-gaps;
      };
    };

    videoDrivers = [
      "vmware"
      "vesa"
      "modesetting"
    ];
  };

  services.autorandr = {
    enable = true;
  };

  home-manager.users."${config.user.name}" = {
    home = {
      packages = with pkgs; [
        _1password-cli
        _1password-gui

        # below needed for host clipboard
        xclip
        gtkmm3
      ];
      file."Pictures/Wallpapers" = {
        recursive = true;
        source = ../../../configs/wallpapers;
      };
    };

    xdg.configFile = {
      "i3/config".source = ../../../configs/i3/config;
    };
    xresources.properties = {
      "Xft.dpi" = dpi;
    };

    xsession.pointerCursor = {
      name = "Vanilla-DMZ";
      package = pkgs.vanilla-dmz;
      size = 128;
    };

    programs.feh.enable = true;
  };

  modules = {
    nix = {
      enable = true;
      dev.enable = true;
    };
    shell = {
      commonPkgs.enable = true;
      openssh.enable = true;
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
      polybar.enable = true;
      rofi.enable = true;
      chromium.enable = true;
    };
    dev = {
      elixir.enable = true;
      idea.enable = true;
      psql.enable = true;
      nodejs.enable = true;
    };
    term = {
      kitty = {
        enable = true;
        fontSize = 13;
      };
    };
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
