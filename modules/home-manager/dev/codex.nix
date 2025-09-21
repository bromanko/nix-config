{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.codex;
  promptsDir = ../../../configs/codex/prompts;
  promptFiles = lib.filterAttrs (_: type: type == "regular") (builtins.readDir promptsDir);
  promptFileNames = builtins.attrNames promptFiles;
in
{
  options.modules.dev.codex = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      programs.codex = {
        enable = true;
        package = pkgs.my.codex;
      };

      home = {
        file = builtins.listToAttrs (
          map (
            name:
            {
              name = ".codex/prompts/${name}";
              value = {
                source = config.hm.lib.file.mkNixConfigSymlink "/configs/codex/prompts/${name}";
              };
            }
          ) promptFileNames
        );
      };
    };
  };
}
