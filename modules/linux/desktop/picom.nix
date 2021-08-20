{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.picom;
in {
  options.modules.desktop.picom = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}" = {
      services.picom = {
        enable = true;

        experimentalBackends = true;
        vSync = true;

        extraOptions = ''
          corner-radius = 20;
          round-borders = 1;
          detect-rounded-corners = true;
          rounded-corners-exclude = [
            "class_g = 'Polybar'"
          ];
        '';
      };
    };
  };
}
