{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.services.feedbin-mcp;
in
{
  options.services.feedbin-mcp = {
    enable = lib.mkEnableOption "Personal Feedbin MCP server";
    domain = lib.mkOption {
      type = lib.types.str;
      default = "feedbin.bromanko.com";
    };
    port = lib.mkOption {
      type = lib.types.port;
      default = 3001;
    };
    allowedEmail = lib.mkOption {
      type = lib.types.str;
      description = "The only Feedbin account allowed to connect.";
    };
  };
  config = lib.mkIf cfg.enable {
    users.groups.feedbin-mcp = { };
    users.users.feedbin-mcp = {
      isSystemUser = true;
      group = "feedbin-mcp";
      home = "/var/lib/feedbin-mcp";
    };
    environment.systemPackages = [
      pkgs.python313
      pkgs.uv
    ];
    systemd.tmpfiles.rules = [
      "d /var/lib/feedbin-mcp 0750 root feedbin-mcp - -"
      "d /var/lib/feedbin-mcp/releases 0750 root feedbin-mcp - -"
      "d /var/lib/feedbin-mcp/state 0700 feedbin-mcp feedbin-mcp - -"
      "f /var/lib/feedbin-mcp/env 0640 root feedbin-mcp - -"
    ];
    systemd.services.feedbin-mcp = {
      description = "Personal Feedbin HTTP MCP and OAuth server";
      after = [ "network-online.target" ];
      wants = [ "network-online.target" ];
      wantedBy = [ "multi-user.target" ];
      unitConfig.ConditionPathExists = "/var/lib/feedbin-mcp/current/.venv/bin/python";
      environment = {
        PUBLIC_BASE_URL = "https://${cfg.domain}";
        ALLOWED_FEEDBIN_EMAIL = cfg.allowedEmail;
        DATABASE_PATH = "/var/lib/feedbin-mcp/state/auth.sqlite";
        PORT = toString cfg.port;
        PYTHONDONTWRITEBYTECODE = "1";
      };
      serviceConfig = {
        User = "feedbin-mcp";
        Group = "feedbin-mcp";
        WorkingDirectory = "/var/lib/feedbin-mcp/current";
        EnvironmentFile = "/var/lib/feedbin-mcp/env";
        ExecStart = "/var/lib/feedbin-mcp/current/.venv/bin/python /var/lib/feedbin-mcp/current/server.py";
        Restart = "on-failure";
        RestartSec = "5s";
        UMask = "0077";
        NoNewPrivileges = true;
        PrivateTmp = true;
        ProtectHome = true;
        ProtectSystem = "strict";
        ReadWritePaths = [ "/var/lib/feedbin-mcp/state" ];
        CapabilityBoundingSet = "";
        LockPersonality = true;
      };
    };
    services.caddy.virtualHosts.${cfg.domain} = {
      # OAuth request IDs and codes must not enter HTTP access logs.
      logFormat = "output discard";
      extraConfig = ''
        request_body {
          max_size 64KB
        }
        reverse_proxy 127.0.0.1:${toString cfg.port}
      '';
    };
  };
}
