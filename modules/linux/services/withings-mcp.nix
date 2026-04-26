{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.services.withings-mcp;
in
{
  options.services.withings-mcp = {
    enable = lib.mkEnableOption "Withings MCP server";

    domain = lib.mkOption {
      type = lib.types.nullOr lib.types.str;
      default = null;
      example = "withings.bromanko.com";
      description = "Public domain served by Caddy for the Withings MCP server.";
    };

    port = lib.mkOption {
      type = lib.types.port;
      default = 3000;
      description = "Loopback port the Withings MCP server listens on.";
    };

    user = lib.mkOption {
      type = lib.types.str;
      default = "withings-mcp";
      description = "User that runs the Withings MCP service.";
    };

    group = lib.mkOption {
      type = lib.types.str;
      default = "withings-mcp";
      description = "Group that runs the Withings MCP service.";
    };

    stateDir = lib.mkOption {
      type = lib.types.str;
      default = "/var/lib/withings-mcp";
      description = "Directory containing releases, current symlink, and env file.";
    };

    environmentFile = lib.mkOption {
      type = lib.types.str;
      default = "${cfg.stateDir}/env";
      description = "Environment file containing Withings, Supabase, and runtime secrets.";
    };

    package = lib.mkPackageOption pkgs "bun" { };
  };

  config = lib.mkIf cfg.enable {
    users.groups.${cfg.group} = { };

    users.users.${cfg.user} = {
      isSystemUser = true;
      inherit (cfg) group;
      home = cfg.stateDir;
      createHome = false;
    };

    systemd.tmpfiles.rules = [
      "d ${cfg.stateDir} 0750 ${cfg.user} ${cfg.group} - -"
      "d ${cfg.stateDir}/releases 0750 ${cfg.user} ${cfg.group} - -"
      "f ${cfg.environmentFile} 0640 root ${cfg.group} - -"
    ];

    systemd.services.withings-mcp = {
      description = "Withings MCP server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = "${cfg.stateDir}/current/index.js";

      serviceConfig = {
        Type = "simple";
        User = cfg.user;
        Group = cfg.group;
        WorkingDirectory = "${cfg.stateDir}/current";
        Environment = [
          "NODE_ENV=production"
          "PORT=${toString cfg.port}"
        ];
        EnvironmentFile = cfg.environmentFile;
        ExecStart = "${cfg.package}/bin/bun ${cfg.stateDir}/current/index.js";
        Restart = "always";
        RestartSec = "5s";
        KillSignal = "SIGINT";
        TimeoutStopSec = "30s";

        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = cfg.stateDir;
        CapabilityBoundingSet = "";
        LockPersonality = true;
      };
    };

    services.caddy.virtualHosts = lib.optionalAttrs (cfg.domain != null) {
      "${cfg.domain}".extraConfig = ''
        reverse_proxy 127.0.0.1:${toString cfg.port}
      '';
    };
  };
}
