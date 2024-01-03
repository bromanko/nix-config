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
  };

  config = mkIf cfg.enable {
    services.synergy = {
      client = mkIf (cfg.mode == "client") {
        enable = true;
        autoStart = true;
      };
      server = mkIf (cfg.mode == "server") {
        enable = true;
        autoStart = true;
      };
    };
  };
}
