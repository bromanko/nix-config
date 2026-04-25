{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.term.eternal-terminal.server;
  etConfig = pkgs.writeText "et.cfg" ''
    ; et.cfg : Config file for Eternal Terminal
    ;

    [Networking]
    port = ${toString cfg.port}
    ${optionalString (cfg.bindIP != null) "bind_ip = ${cfg.bindIP}"}

    [Debug]
    verbose = ${toString cfg.verbosity}
    silent = ${if cfg.silent then "1" else "0"}
    logsize = ${toString cfg.logSize}
    logdirectory = ${cfg.logDirectory}
  '';
in
{
  options.modules.term.eternal-terminal.server = with types; {
    enable = mkBoolOpt false;

    package = mkOption {
      type = package;
      default = pkgs.eternal-terminal;
      description = "Eternal Terminal package to use for the server.";
    };

    port = mkOption {
      type = port;
      default = 2022;
      description = "Port the Eternal Terminal server should listen on.";
    };

    bindIP = mkOption {
      type = nullOr str;
      default = null;
      description = "Optional IP address for the Eternal Terminal server to bind.";
    };

    verbosity = mkOption {
      type = enum (range 0 9);
      default = 0;
      description = "Eternal Terminal server verbosity level (0-9).";
    };

    silent = mkBoolOpt false;

    logSize = mkOption {
      type = int;
      default = 20971520;
      description = "Maximum Eternal Terminal server log file size.";
    };

    logDirectory = mkOption {
      type = str;
      default = "/var/log/eternal-terminal";
      description = "Directory where etserver should write logs.";
    };

    openFirewall = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ cfg.package ];

    networking.firewall.allowedTCPPorts = mkIf cfg.openFirewall [ cfg.port ];

    systemd.tmpfiles.rules = [
      "d ${cfg.logDirectory} 0755 root root -"
    ];

    systemd.services.eternal-terminal = {
      description = "Eternal Terminal server";
      wantedBy = [ "multi-user.target" ];
      after = [ "network.target" ];
      serviceConfig = {
        ExecStart = "${cfg.package}/bin/etserver --cfgfile=${etConfig}";
        Restart = "on-failure";
      };
    };
  };
}
