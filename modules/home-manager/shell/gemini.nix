{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.gemini;
in
{
  options.modules.shell.gemini = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        packages = [
          pkgs.gemini-cli
        ];
        file = {
          ".gemini/settings.json".source =
            config.hm.lib.file.mkNixConfigSymlink ../../../configs/gemini/settings.json;
        };
      };

      programs.fish.shellAliases = {
        gemini-yolo = "gemini --yolo";
      };
    };
  };
}
