{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.apps.vimari;
in {
  options.modules.desktop.apps.vimari = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    modules.homebrew = { masApps = { Vimari = 1480933944; }; };

    home-manager.users."${config.user.name}".home.file."Library/Containers/net.televator.Vimari.SafariExtension/Data/Library/Application Support/userSettings.json" =
      {
        source = ../../../../configs/vimari/userSettings.json;
      };
  };
}
