{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.claude-code;
in
{
  options.modules.dev.claude-code = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        packages = with pkgs; [
          my.claude-code
        ];
        file = {
          ".claude/CLAUDE.md".source = config.hm.lib.file.mkNixConfigSymlink "/configs/claude/CLAUDE.md";
        };
      };

      programs.fish.shellAliases = {
        claude-yolo = "claude --dangerously-skip-permissions";
      };
    };
  };
}
