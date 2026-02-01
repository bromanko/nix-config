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
in
{
  options.modules.dev.codex = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      programs.codex = {
        enable = true;
        package = pkgs.llm-agents.codex;
      };

      home.file.".codex/prompts" = {
        source = ../../../configs/codex/prompts;
        recursive = true;
      };
    };
  };
}
