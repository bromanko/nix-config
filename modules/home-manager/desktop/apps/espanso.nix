{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.apps.espanso;
in {
  options.modules.desktop.apps.espanso = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home.file."Library/Preferences/espanso/user" = {
      recursive = true;
      source = ../../../../configs/espanso/user;
    };
  };
}
