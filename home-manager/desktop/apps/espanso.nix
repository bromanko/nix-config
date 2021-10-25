{ config, lib, pkgs, ... }:

with lib;
let cfg = config.modules.desktop.apps.espanso;
in {
  config = mkIf cfg.enable {
    home.file."Library/Preferences/espanso" = {
      recursive = true;
      source = ../../../configs/espanso;
    };
  };
}
