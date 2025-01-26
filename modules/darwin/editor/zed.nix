{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.editor.zed;
in
{
  options.modules.editor.zed = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    modules.homebrew = {
      casks = [ "zed@preview" ];
    };

    hm = {
      home = {
        packages = with pkgs; [ nixd ];
      };
      xdg = {
        configFile = {
          "zed/settings.json".source = config.hm.lib.file.mkNixConfigSymlink "/configs/zed/settings.json";
          "zed/keymap.json".source = config.hm.lib.file.mkNixConfigSymlink "/configs/zed/keymap.json";
        };
      };
    };
  };
}
