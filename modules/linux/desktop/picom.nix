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
        backend = "glx";

        shadow = true;
        shadowExclude = [
          "name = 'Polybar'"
          "name *= 'compton'"
          "name *= 'picom'"
          "class_g = 'Polybar'"
          # "class_g ?= 'i3-frame'"
        ];
        shadowOpacity = "0.4";
        shadowOffsets = [ (0 - 12) (0 - 6) ];

        fade = true;
        fadeSteps = [ "055.0" "0.066" ];

        extraOptions = ''
          glx-no-stencil = true;
          shadow-ignore-shaped = false;
          no-fading-openclose = false;
          detect-client-opacity = true;

          shadow-radius = 12;
          corner-radius = 12;
          round-borders = 1;
          detect-rounded-corners = true;
          rounded-corners-exclude = [ "class_g = 'Polybar'" ];

          focus-exclude = [ "class_g = 'Polybar'" ];
        '';
      };
    };
  };
}
