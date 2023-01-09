{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.apps.hammerspoon;
in {
  options.modules.desktop.apps.hammerspoon = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    modules.homebrew = {
      taps = [ "homebrew/cask" ];
      casks = [ "hammerspoon" ];
    };
  };
}
