{
  config,
  lib,
  pkgs,
  inputs,
  modulesPath,
  ...
}:
let
  scherzoCloud = pkgs.callPackage ../../../../packages/scherzo-cloud.nix { };
  proxyTools = lib.hiPrio (import ../../../../packages/scherzo-proxy-tools.nix { inherit pkgs; });
  pi = pkgs.callPackage ../../../../packages/pi.nix { };
  devenv = inputs.scherzo-devenv.packages.${pkgs.stdenv.hostPlatform.system}.devenv;
  cargoJobs = 1;
  runnerCargoConfig = pkgs.writeText "scherzo-runner-cargo-config" ''
    [build]
    jobs = ${toString cargoJobs}
  '';
  runnerGitConfig = pkgs.writeText "scherzo-runner-gitconfig" ''
    [user]
      name = Scherzo Cloud Runner
      email = scherzo-runner@localhost
  '';
  publicationPlaceholder = pkgs.writeText "scherzo-publication-placeholder" "{{scherzo:GITHUB_TOKEN}}";
in
{
  imports = [
    (modulesPath + "/profiles/qemu-guest.nix")
    inputs.nixos-lima.nixosModules.lima
  ];

  services.lima.enable = true;
  programs.fish.enable = true;
  networking.hostName = "lima-scherzo";
  boot = {
    growPartition = true;
    loader.grub = {
      device = "nodev";
      efiSupport = true;
      efiInstallAsRemovable = true;
      configurationLimit = 3;
    };
    tmp.cleanOnBoot = true;
  };
  fileSystems."/boot" = {
    device = lib.mkForce "/dev/vda1";
    fsType = "vfat";
  };
  fileSystems."/" = {
    device = "/dev/disk/by-label/nixos";
    fsType = "ext4";
    autoResize = true;
    options = [
      "noatime"
      "discard"
    ];
  };
  swapDevices = [
    {
      device = "/swapfile";
      size = 2048;
    }
  ];

  # Lima manages the bootstrap SSH identity. No forwarded developer agent,
  # personal credentials, or interactive home configuration is needed.
  authorizedKeys = lib.mkForce [ ];
  users.users.${config.user.name} = {
    home = lib.mkForce "/home/${config.user.name}.linux";
    linger = true;
  };
  hm.home.homeDirectory = lib.mkForce "/home/${config.user.name}.linux";
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "no";
      PasswordAuthentication = false;
    };
  };
  security.sudo.wheelNeedsPassword = false;
  modules.homeage.enable = false;
  modules.nix.system.keepOutputs = false;
  nix = {
    gc = {
      dates = lib.mkForce "daily";
      options = lib.mkForce "--delete-older-than 3d";
    };
    settings = {
      max-jobs = 1;
      cores = 2;
      min-free = 5 * 1024 * 1024 * 1024;
      max-free = 10 * 1024 * 1024 * 1024;
    };
  };

  environment.systemPackages = [
    scherzoCloud
    proxyTools
    pi
    devenv
    pkgs.jq
    pkgs.python3
    pkgs.jujutsu
  ];
  users.groups.scherzo-runner = { };
  users.users.scherzo-runner = {
    isSystemUser = true;
    group = "scherzo-runner";
    home = "/var/lib/scherzo-cloud";
  };
  # Enrollment rejects symlinks: materialize a regular, non-secret config file.
  environment.etc."scherzo/runner.json".mode = "0644";
  environment.etc."scherzo/runner.json".text = builtins.toJSON {
    schemaVersion = 1;
    deploymentMode = "production";
    runnerStatePath = "/var/lib/scherzo-cloud/runner-state.json";
    controlSocketPath = "/run/scherzo-cloud/runner.sock";
    workRoot = "/var/lib/scherzo-cloud/work";
  };
  systemd.tmpfiles.rules = [
    "d /var/lib/scherzo-cloud 0700 scherzo-runner scherzo-runner -"
    "d /var/lib/scherzo-cloud/work 0700 scherzo-runner scherzo-runner -"
  ];
  systemd.services.scherzo-runner = {
    description = "Scherzo Cloud Runner Serve";
    wants = [ "network-online.target" ];
    after = [ "network-online.target" ];
    wantedBy = [ "multi-user.target" ];
    unitConfig.ConditionPathExists = "/var/lib/scherzo-cloud/runner-state.json";
    path = [
      scherzoCloud
      proxyTools
      pi
      pkgs.bash
      pkgs.coreutils
      pkgs.jq
      pkgs.python3
      pkgs.jujutsu
      pkgs.nix
      pkgs.gnugrep
      pkgs.gnused
      pkgs.gawk
      pkgs.findutils
      pkgs.gnutar
      pkgs.gzip
      pkgs.openssh
      devenv
    ];
    preStart = ''
      # This regular owner-private file contains only a public placeholder.
      # The existing operator-approved publication token stays in the host proxy.
      install -m 0600 ${publicationPlaceholder} /var/lib/scherzo-cloud/github-publish-placeholder
      # Managed workloads intentionally strip GIT_CONFIG_* environment overrides.
      install -m 0644 ${runnerGitConfig} /var/lib/scherzo-cloud/.gitconfig
      # Clean repository test shells retain HOME but drop CARGO_BUILD_JOBS.
      install -d -m 0700 /var/lib/scherzo-cloud/.cargo
      install -m 0644 ${runnerCargoConfig} /var/lib/scherzo-cloud/.cargo/config.toml
    '';
    environment = {
      HOME = "/var/lib/scherzo-cloud";
      # Cargo concurrency is independent of the Nix daemon's max-jobs setting.
      CARGO_BUILD_JOBS = toString cargoJobs;
      PI_CODING_AGENT_DIR = "/var/lib/scherzo-cloud/.pi/agent";
      XDG_RUNTIME_DIR = "/run/scherzo-cloud";
      GITHUB_PUBLISH_TOKEN_FILE = "/var/lib/scherzo-cloud/github-publish-placeholder";
      # Shared workflow Linear transport: no interpreter or global proxy override.
      LINEAR_API_KEY = "{{scherzo:LINEAR_API_KEY}}";
      LINEAR_PROXY_URL = "http://127.0.0.1:17329";
      LINEAR_PROXY_CA_FILE = "${proxyTools.caBundle}";
      SSL_CERT_FILE = "${pkgs.cacert}/etc/ssl/certs/ca-bundle.crt";
    };
    serviceConfig = {
      Type = "simple";
      User = "scherzo-runner";
      Group = "scherzo-runner";
      ExecStart = "${scherzoCloud}/bin/scherzo-cloud runner serve --config /etc/scherzo/runner.json";
      Restart = "on-failure";
      # Work-root recovery requires an operator, not an automatic restart loop.
      RestartPreventExitStatus = [ 5 ];
      RestartSec = "5s";
      KillSignal = "SIGTERM";
      KillMode = "mixed";
      TimeoutStopSec = "325s";
      SendSIGKILL = true;
      RuntimeDirectory = "scherzo-cloud";
      RuntimeDirectoryMode = "0700";
      StateDirectory = "scherzo-cloud";
      StateDirectoryMode = "0700";
      UMask = "0077";
      NoNewPrivileges = true;
      PrivateTmp = true;
      ProtectHome = true;
      ProtectSystem = "strict";
      ReadWritePaths = [
        "/var/lib/scherzo-cloud"
        "/run/scherzo-cloud"
      ];
      RestrictAddressFamilies = [
        "AF_INET"
        "AF_INET6"
        "AF_UNIX"
      ];
      RestrictSUIDSGID = true;
      LockPersonality = true;
    };
  };
  system.stateVersion = "25.11";
}
