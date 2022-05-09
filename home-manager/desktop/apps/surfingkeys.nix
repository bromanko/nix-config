{ config, lib, pkgs, ... }:

with lib;
let cfg = config.modules.desktop.apps.surfingkeys;
in {
  config = mkIf cfg.enable {
    xdg.configFile."surfingkeys/surfingkeys.js".source =
      ../../../configs/surfingkeys/surfingkeys.js;
  };
}
