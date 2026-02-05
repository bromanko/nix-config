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

  # Secret proxy client — route HTTP(S) through the host's secret-proxy
  # which injects 1Password secrets via {{PLACEHOLDER}} patterns in headers.
  # The proxy is accessible via SSH reverse tunnel (see configs/lima/dev.yaml).
  networking.proxy = {
    httpProxy = "http://127.0.0.1:17329";
    httpsProxy = "http://127.0.0.1:17329";
    noProxy = "localhost,127.0.0.1,::1,10.0.0.0/8,172.16.0.0/12,192.168.0.0/16";
  };

  # Trust the mitmproxy CA certificate so HTTPS inspection works
  security.pki.certificateFiles =
    let
      certPath = ../../../../configs/secret-proxy/mitmproxy-ca-cert.pem;
    in
    lib.optional (builtins.pathExists certPath) certPath;

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
      enable = false;
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
      # Placeholder tokens — replaced by secret-proxy with real values from
      # the host's 1Password Environment. See configs/secret-proxy/README.md.
      sessionVariables = {
        GH_TOKEN = "{{GITHUB_TOKEN}}";
        OPENAI_API_KEY = "{{OPENAI_API_KEY}}";
        GEMINI_API_KEY = "{{GEMINI_API_KEY}}";
      };
    };

    programs.fish.shellAliases = {
      rebuild = "sudo nixos-rebuild switch --flake ~/Code/nix-config#lima-dev";
    };
  };

  system.stateVersion = "25.11";
}
