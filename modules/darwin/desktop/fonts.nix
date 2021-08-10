{ config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.fonts;

in { config = mkIf cfg.enable { fonts = { enableFontDir = true; }; }; }
