{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}:

{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.nixos-lima.nixosModules.lima
    inputs.determinate.nixosModules.default
  ];

  # Lima guest agent and boot-time configuration
  services.lima.enable = true;

  # Boot configuration (matches nixos-lima image layout)
  boot = {
    kernelPackages = pkgs.linuxPackages_latest;
    kernelParams = [ "console=tty0" ];
    loader.grub = {
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;
    };
    tmp = {
      useTmpfs = true;
    };
  };

  fileSystems."/boot" = {
    device = lib.mkForce "/dev/vda1";
    fsType = "vfat";
  };

  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    autoResize = true;
    fsType = "ext4";
    options = [
      "noatime"
      "nodiratime"
      "discard"
    ];
  };

  # Networking
  networking.hostName = "lima-dev";

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };

  # Sudo
  security.sudo.wheelNeedsPassword = false;

  # Nix configuration
  modules.nix.system.enable = "default";

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    trusted-users = [ "@wheel" ];
  };

  # Override user home directory to match Lima's convention (appends .linux)
  users.users.${config.user.name}.home = lib.mkForce "/home/${config.user.name}.linux";

  # Enable fish system-wide (needed for user shell)
  programs.fish.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    ncurses
  ];

  # Module configuration (defines both system and HM settings via hm.* internally)
  modules = {
    nix = {
      dev.enable = true;
    };
    homeage = {
      enable = true;
    };
    shell = {
      commonPkgs.enable = true;
      openssh.enable = true;
      ssh.enable = true;
      "1password".enable = true;
      fish.enable = true;
      bat.enable = true;
      git.enable = true;
      jujutsu.enable = true;
      starship.enable = true;
      fzf.enable = true;
      direnv.enable = true;
      exa.enable = true;
      fd.enable = true;
      gemini.enable = true;
    };
    dev = {
      elixir.enable = true;
      idea.enable = true;
      psql.enable = true;
      nodejs.enable = true;
      codex.enable = true;
      claude-code.enable = true;
      pi.enable = true;
    };
    editor = {
      default = "nvim";
      neovim.enable = true;
    };
  };

  # Home Manager user configuration
  hm = {
    home = {
      homeDirectory = lib.mkForce "/home/bromanko.linux";
      packages = with pkgs; [
        ncurses
        devenv
      ];
    };

    programs.fish.shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ~/Code/nix-config#lima-dev";
    };
  };

  system.stateVersion = "25.11";
}
