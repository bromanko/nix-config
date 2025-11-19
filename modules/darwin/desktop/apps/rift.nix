{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.rift;
in
{
  options.modules.desktop.apps.rift = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home.packages = [ pkgs.my.rift ];

      # Symlink config from repo (out-of-store path)
      xdg.configFile."rift/config.toml".source =
        config.hm.lib.file.mkNixConfigSymlink "/configs/rift/config.toml";

      # Launchd agent for auto-start
      launchd.agents.rift = {
        enable = true;
        config = {
          ProgramArguments = [ "${pkgs.my.rift}/bin/rift" ];
          RunAtLoad = true;
          KeepAlive = true;
          ProcessType = "Interactive";
          StandardOutPath = "${config.hm.home.homeDirectory}/Library/Logs/rift.log";
          StandardErrorPath = "${config.hm.home.homeDirectory}/Library/Logs/rift.log";
        };
      };
    };
  };
}
