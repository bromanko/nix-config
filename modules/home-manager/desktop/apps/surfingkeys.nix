{
  config,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.surfingkeys;
in
{
  options.modules.desktop.apps.surfingkeys = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      xdg.configFile."surfingkeys/surfingkeys.js".source = ../../../../configs/surfingkeys/surfingkeys.js;
    };
  };
}
