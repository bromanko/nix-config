{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.tailscale;
in {
  options.modules.tailscale = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.tailscale ];

    services.tailscale.enable = true;

    systemd.services.tailscale-autoconnect = {
      description = "Automatic connection to Tailscale";
    };
  };
}
