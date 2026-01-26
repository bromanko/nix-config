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
  cfg = config.modules.desktop.polybar;
in
{
  options.modules.desktop.polybar = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}" = {
      services.polybar = {
        enable = true;
        package = pkgs.polybar.override { i3GapsSupport = true; };
        config = ../../../configs/polybar/config.ini;
        script = "polybar -r main &";
      };
    };
  };
}
