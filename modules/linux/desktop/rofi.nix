{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.rofi;
in {
  options.modules.desktop.rofi = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}" = {
      programs.rofi = {
        enable = true;
        plugins = with pkgs; [ rofi-calc ];
      };
    };
  };
}
