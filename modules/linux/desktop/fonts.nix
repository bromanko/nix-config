{ config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.fonts;

in {
  config = mkIf cfg.enable {
    fonts = {
      fontconfig = {
        hinting.enable = false;
        subpixel.lcdfilter = "none";
      };
    };
  };
}
