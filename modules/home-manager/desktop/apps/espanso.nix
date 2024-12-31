{ config, lib, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.espanso;
in
{
  options.modules.desktop.apps.espanso = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm.home.file."Library/Preferences/espanso" = {
      recursive = true;
      source = ../../../../configs/espanso;
    };
  };
}
