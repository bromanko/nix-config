{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.apps.synergy;
in {
  options.modules.desktop.apps.synergy = with types; {
    enable = mkBoolOpt false;
    mode = mkOption {
      type = types.enum [ "client" "server" ];
      default = "client";
      description = "Whether to run as a client or server.";
    };
    serverAddress = mkOption {
      type = str;
      description = ''
        The server address of the form [hostname][:port]. The hostname must be
        the address or hostname of the server. The port overrides the default port, 24800.
      '';
    };
  };

  config = mkIf cfg.enable {
    services.synergy = {
      client = mkIf (cfg.mode == "client") {
        enable = true;
        autoStart = true;
        serverAddress = cfg.serverAddress;
      };
      server = mkIf (cfg.mode == "server") {
        enable = true;
        autoStart = true;
      };
    };
  };
}
