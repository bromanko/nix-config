{
  config,
  options,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.tailscale;
in
{
  options.modules.tailscale = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.tailscale ];

    services.tailscale.enable = true;
  };
}
