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
  homeDir =
    if config ? home && config.home ? homeDirectory then
      config.home.homeDirectory
    else
      config.users.users.${config.user.name}.home;

  resolveTildePath = path: if hasPrefix "~/" path then homeDir + removePrefix "~" path else path;
  skillDirectories = map resolveTildePath cfg.skillDirectories;
in
{
  options.modules.dev.codex = with types; {
    enable = mkBoolOpt false;

    package = mkOption {
      type = nullOr package;
      default = pkgs.llm-agents.codex;
      description = "Codex package to install, or null when managed externally";
    };

    skillDirectories = mkOption {
      type = listOf str;
      default = [
        "~/Code/llm-agents/skills"
        "~/Code/llm-agents-private/shared/skills"
      ];
      description = "Directories containing personal skills to expose to ChatGPT and Codex";
    };
  };

  config = mkIf cfg.enable {
    hm = {
      programs.codex = {
        enable = true;
        package = cfg.package;
      };

      home = {
        activation.linkCodexSkills = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          skills_target=${escapeShellArg "${homeDir}/.agents/skills"}
          $DRY_RUN_CMD mkdir -p "$skills_target"

          for skills_source in ${escapeShellArgs skillDirectories}; do
            if [[ ! -d "$skills_source" ]]; then
              continue
            fi

            for skill in "$skills_source"/*; do
              if [[ ! -f "$skill/SKILL.md" ]]; then
                continue
              fi

              target="$skills_target/''${skill##*/}"
              if [[ -e "$target" && ! -L "$target" ]]; then
                echo "Skipping Codex skill $skill: $target already exists and is not a symlink" >&2
                continue
              fi

              $DRY_RUN_CMD ln -sfn "$skill" "$target"
            done
          done
        '';

        file.".codex/prompts" = {
          source = ../../../configs/codex/prompts;
          recursive = true;
        };
      };
    };
  };
}
