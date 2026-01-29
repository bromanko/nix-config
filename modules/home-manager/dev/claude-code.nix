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
        packages = [
          pkgs.my.claude-code
          pkgs.my.ccstatusline
        ];
        file = {
          ".claude/CLAUDE.md".source = config.hm.lib.file.mkNixConfigSymlink "/configs/claude/CLAUDE.md";
          ".claude/settings.json".source =
            config.hm.lib.file.mkNixConfigSymlink "/configs/claude/settings.json";
        };
      };

      xdg.configFile = {
        "ccstatusline/settings.json".source =
          config.hm.lib.file.mkNixConfigSymlink "/configs/ccstatusline/settings.json";
      };

      programs.fish.shellAliases = {
        claude-yolo = "claude --dangerously-skip-permissions";
      };
    };
  };
}
