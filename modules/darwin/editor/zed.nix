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

    hm.home = {
      packages = with pkgs; [ nixd ];
      activation.zedConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if [ ! -f "$HOME/.config/zed/settings.json" ]; then
          echo "Writing Zed settings.json"
          cp ${../../../configs/zed/settings.json} "$HOME/.config/zed/settings.json"
        else
          if ! cmp ${../../../configs/zed/settings.json} "$HOME/.config/zed/settings.json"; then
            echo "Zed settings.json exists and is different"
            exit 1
          fi
        fi
        if [ ! -f "$HOME/.config/zed/keymap.json" ]; then
          echo "Writing Zed keymap.json"
          cp ${../../../configs/zed/keymap.json} "$HOME/.config/zed/keymap.json"
        else
          if ! cmp ${../../../configs/zed/keymap.json} "$HOME/.config/zed/keymap.json"; then
            echo "Zed keymap.json exists and is different"
            exit 1
          fi
        fi
      '';
    };
  };
}
