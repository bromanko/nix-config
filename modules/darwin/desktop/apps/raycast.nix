{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.apps.raycast;
in {
  options.modules.desktop.apps.raycast = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    modules.homebrew = { casks = [ "raycast" ]; };

    home-manager.users."${config.user.name}".home.file.".config/raycast" = {
      recursive = true;
      source = ../../../../configs/raycast;
    };
  };
}
