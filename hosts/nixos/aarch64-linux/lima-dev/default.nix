{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}:

let
  noProxyHosts = [
    "localhost"
    "127.0.0.1"
    "::1"
    "10.0.0.0/8"
    "172.16.0.0/12"
    "192.168.0.0/16"
    "cache.nixos.org"
    "install.determinate.systems"
    "devenv.cachix.org"
    "cache.numtide.com"
    "flakehub.com"
    "api.flakehub.com"
    "cache.flakehub.com"
    "*.githubusercontent.com"
    # OAuth login/token-exchange traffic uses credentials already held by pi.
    # It does not contain secret-proxy placeholders, and login should keep
    # working even if the Lima reverse tunnel is not yet established.
    "platform.claude.com"
    "claude.ai"
    "chatgpt.com"
    "auth.openai.com"
    "status.openai.com"
  ];
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.nixos-lima.nixosModules.lima
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
      configurationLimit = 3;
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

  # Keep first rebuilds from being killed by memory spikes while large
  # development closures are being realised.
  swapDevices = [
    {
      device = "/swapfile";
      size = 12288;
    }
  ];

  # Networking
  networking.hostName = "lima-dev";

  # Secret proxy client — route HTTP(S) through the host's secret-proxy
  # which injects 1Password secrets via {{PLACEHOLDER}} patterns in headers.
  # The proxy is accessible via SSH reverse tunnel (see configs/lima/dev.yaml).
  networking.proxy = {
    httpProxy = "http://127.0.0.1:17329";
    httpsProxy = "http://127.0.0.1:17329";
    noProxy = lib.concatStringsSep "," noProxyHosts;
  };

  # Trust the mitmproxy CA certificate so HTTPS inspection works.
  # Use the compatible bundle format (plain PEM, no p11-kit trust rules)
  # so that all OpenSSL consumers can verify the MITM CA.
  security.pki.useCompatibleBundle = true;
  security.pki.certificateFiles = [ ../../../../packages/secret-proxy/mitmproxy-ca-cert.pem ];

  # SSH
  services.openssh = {
    enable = true;
    settings = {
      AcceptEnv = [ "LIMA_SSH_AGENT_BRIDGE" ];
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
    max-jobs = 1;
    cores = 2;
  };

  # Override user home directory to match Lima's convention (appends .linux).
  # Enable linger so the user systemd session (and dbus socket) stays alive
  # even without an active login — needed for `nixos-rebuild switch` to reload
  # user units without errors.
  users.users.${config.user.name} = {
    home = lib.mkForce "/home/${config.user.name}.linux";
    linger = true;
  };

  # Enable fish system-wide (needed for user shell)
  programs.fish.enable = true;

  # System packages
  environment.systemPackages = with pkgs; [
    vim
    git
    ghostty # terminfo for host terminal
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
      codex.enable = false;
      claude-code.enable = true;
      pi.enable = true;
    };
    term = {
      tmux.enable = true;
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
      # the host's 1Password Environment. See packages/secret-proxy/README.md.
      sessionVariables = {
        GH_TOKEN = "{{GITHUB_TOKEN}}";
        BRAVE_API_KEY = "{{BRAVE_API_KEY}}";
        JJ_EDITOR = "nvim";
        # Node.js ignores the system CA store; point it at the NixOS bundle
        # which includes the mitmproxy CA from security.pki.certificateFiles.
        NODE_EXTRA_CA_CERTS = "/etc/ssl/certs/ca-certificates.crt";
      };
    };

    programs = {
      fish = {
        shellAliases = {
          "rebuild!" = "sudo nixos-rebuild switch --flake ~/Code/nix-config#lima-dev";
        };
        interactiveShellInit = lib.mkAfter ''
          # OpenSSH's ~/.ssh/rc has now captured the concrete forwarded agent
          # socket. Use its stable symlink in persistent shells such as tmux.
          if test -S "$HOME/.ssh/agent.sock"
            set -gx SSH_AUTH_SOCK "$HOME/.ssh/agent.sock"
          end
        '';
      };
      jujutsu.settings.ui.editor = "nvim";

      # Managed Git operations use the dedicated host-maintained agent bridge,
      # not the ephemeral socket associated with Lima's SSH control master.
      ssh.settings.github-scherzo-agent = {
        IdentityAgent = "~/.ssh/host-agent.sock";
        AddKeysToAgent = "no";
        BatchMode = "yes";
      };

      # Bypass the MITM proxy for git operations to github.com so that
      # git/jj can fetch without needing to trust the proxy CA.
      # API calls (api.github.com) still go through the proxy for
      # {{GITHUB_TOKEN}} injection.
      git.extraConfig.http."https://github.com".proxy = "";
    };
  };

  system.stateVersion = "25.11";
}
