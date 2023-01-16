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
    hm = {
      home = {
        packages = with pkgs; [
          lua53Packages.luarocks # Required for spacehammer
          lua53Packages.fennel # Required for spacehammer
          my.spacehammer
        ];
        file = {
          hammerspoonCfg = {
            source = pkgs.symlinkJoin {
              name = "hammerspoonCfg";
              paths = [
                pkgs.my.spacehammer
                "${pkgs.lua53Packages.fennel}/share/lua/5.3"
              ];
            };
            target = ".hammerspoon";
            recursive = true;
          };
          spacehammerCfg = {
            source = ../../../../configs/hammerspoon/spacehammer;
            target = ".spacehammer";
            recursive = true;
          };
        };
      };
    };
  };
}
