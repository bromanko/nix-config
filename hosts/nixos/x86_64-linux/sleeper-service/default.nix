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
    inputs.determinate.nixosModules.default
  ];

  networking.hostName = "sleeper-service";
  time.timeZone = "America/Los_Angeles";

  # NOTE: Bootstrapped from nixos-infect on Hetzner.
  # Root and EFI partitions are addressed by UUID from `lsblk -f`.
  fileSystems."/" = {
    device = "/dev/disk/by-uuid/45366923-8d88-46c0-9b93-f8bbaac9c5c8";
    fsType = "ext4";
    options = [
      "noatime"
      "nodiratime"
      "discard"
    ];
  };

  fileSystems."/efi" = {
    device = "/dev/disk/by-uuid/352C-FCAB";
    fsType = "vfat";
  };

  # Keep swap persistent on this low-memory host to reduce OOM risk during
  # large Nix builds (for example, Determinate Nix compilation).
  swapDevices = [
    {
      device = "/swapfile";
      size = 8192;
    }
  ];

  boot.loader.systemd-boot.enable = true;
  boot.loader.efi = {
    efiSysMountPoint = "/efi";
    canTouchEfiVariables = true;
  };

  services.openssh = {
    enable = true;
    settings = {
      PasswordAuthentication = false;
      PermitRootLogin = "prohibit-password";
    };
  };

  users.users.root.openssh.authorizedKeys.keys = config.authorizedKeys;

  programs.fish.enable = true;

  networking.firewall.allowedTCPPorts = [
    22
    80
    443
  ];

  # Caddy terminates TLS and forwards requests to hosted personal services.
  services.caddy = {
    enable = true;
    email = "hello@bromanko.com";

    virtualHosts."cal.bromanko.com".extraConfig = ''
      reverse_proxy 127.0.0.1:8000
    '';
  };

  services.withings-mcp = {
    enable = true;
    domain = "withings.bromanko.com";
  };

  users.groups.michael = { };
  users.users.michael = {
    isSystemUser = true;
    group = "michael";
    home = "/var/lib/michael";
    createHome = true;
  };

  # Michael runs as one always-on process:
  # - API
  # - static frontend assets
  # - in-process calendar sync
  #
  # Deploy artifact should be copied to /var/lib/michael/current.
  systemd.services.michael = {
    description = "Michael scheduling service";
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    wants = [ "network-online.target" ];
    unitConfig.ConditionPathExists = "/var/lib/michael/current/Michael.dll";

    serviceConfig = {
      User = "michael";
      Group = "michael";
      WorkingDirectory = "/var/lib/michael/current";
      ExecStart = "${pkgs.dotnetCorePackages.aspnetcore_9_0}/bin/dotnet /var/lib/michael/current/Michael.dll";
      Restart = "always";
      RestartSec = "5s";
      Environment = "ASPNETCORE_URLS=http://127.0.0.1:8000";
      EnvironmentFile = "-/var/lib/michael/env";
      StateDirectory = "michael";
      StateDirectoryMode = "0750";
    };
  };

  # Hourly SQLite backups to local disk and optional offsite upload to S3-
  # compatible object storage.
  #
  # Offsite upload is enabled by creating /var/lib/michael/backup-upload.env
  # with:
  # - AWS_ACCESS_KEY_ID
  # - AWS_SECRET_ACCESS_KEY
  # - AWS_REGION (or AWS_DEFAULT_REGION)
  # - MICHAEL_BACKUP_S3_BUCKET
  # Optional:
  # - MICHAEL_BACKUP_S3_ENDPOINT (for S3-compatible providers)
  # - MICHAEL_BACKUP_S3_PREFIX (default: michael/sqlite)
  systemd.services.michael-backup = {
    description = "Create hourly SQLite backup for Michael";
    serviceConfig = {
      Type = "oneshot";
      User = "michael";
      Group = "michael";
    };
    path = [
      pkgs.bash
      pkgs.coreutils
      pkgs.findutils
      pkgs.sqlite
      pkgs.awscli2
    ];
    script = ''
      set -euo pipefail

      db_path=/var/lib/michael/michael.db
      if [ ! -f "$db_path" ]; then
        echo "Expected SQLite database at $db_path" >&2
        exit 1
      fi

      backup_dir=/var/lib/michael/backups
      mkdir -p "$backup_dir"

      ts=$(date -u +%Y%m%dT%H%M%SZ)
      backup_name="michael-$ts.db"
      backup_file="$backup_dir/$backup_name"

      sqlite3 "$db_path" ".backup '$backup_file'"

      # Keep two weeks of hourly backups locally.
      find "$backup_dir" -type f -name 'michael-*.db' -mtime +14 -delete

      # Optional offsite upload to object storage.
      if [ -f /var/lib/michael/backup-upload.env ]; then
        set -a
        . /var/lib/michael/backup-upload.env
        set +a

        : "''${MICHAEL_BACKUP_S3_BUCKET:?Missing MICHAEL_BACKUP_S3_BUCKET}"

        endpoint_args=()
        if [ -n "''${MICHAEL_BACKUP_S3_ENDPOINT:-}" ]; then
          endpoint_args=(--endpoint-url "$MICHAEL_BACKUP_S3_ENDPOINT")
        fi

        host_name=$(cat /proc/sys/kernel/hostname)
        object_prefix="''${MICHAEL_BACKUP_S3_PREFIX:-michael/sqlite}"
        object_key="''${object_prefix%/}/$host_name/$backup_name"

        aws "''${endpoint_args[@]}" s3 cp "$backup_file" "s3://$MICHAEL_BACKUP_S3_BUCKET/$object_key"
      fi

      # Optional custom hook.
      if [ -x /var/lib/michael/backup-upload ]; then
        /var/lib/michael/backup-upload "$backup_file"
      fi
    '';
  };

  systemd.timers.michael-backup = {
    description = "Run Michael backup hourly";
    wantedBy = [ "timers.target" ];
    timerConfig = {
      OnCalendar = "hourly";
      Persistent = true;
      RandomizedDelaySec = "5m";
      Unit = "michael-backup.service";
    };
  };

  modules = {
    nix.system.enable = "default";
  };

  environment.systemPackages = with pkgs; [
    git
    sqlite
    curl
    htop
  ];

  system.stateVersion = "25.11";
}
