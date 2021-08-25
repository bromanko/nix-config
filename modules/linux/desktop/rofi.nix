{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.rofi;
in {
  options.modules.desktop.rofi = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}" = {
      xdg.configFile = {
        "rofi/themes" = {
          recursive = true;
          source = ../../../configs/rofi/themes;
        };
      };

      programs.rofi = {
        enable = true;
        plugins = with pkgs; [ rofi-calc ];
        theme = "spotlight";
      };
    };
  };
}
