{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.activitywatch;
in
{
  options.modules.desktop.apps.activitywatch = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    modules.homebrew = {
      casks = [ "activitywatch" ];
    };
  };
}
