{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.pi;
  homeDir =
    if config ? home && config.home ? homeDirectory then
      config.home.homeDirectory
    else
      config.users.users.${config.user.name}.home;

  # Resolve ~/ prefixes to the user's home directory
  resolveTildePath = p: if hasPrefix "~/" p then homeDir + removePrefix "~" p else p;

  resolvedSettings =
    cfg.settings
    // (optionalAttrs (cfg.settings ? packages) {
      packages = map resolveTildePath cfg.settings.packages;
    })
    // (optionalAttrs (cfg.settings ? extensions) {
      extensions = map resolveTildePath cfg.settings.extensions;
    });

  settingsFile = pkgs.writeText "pi-settings.json" (builtins.toJSON resolvedSettings);
  designStudioFile = pkgs.writeText "pi-design-studio.json" (builtins.toJSON cfg.designStudio);
in
{
  options.modules.dev.pi = with types; {
    enable = mkBoolOpt false;

    # Freeform settings written to ~/.pi/agent/settings.json.
    # Paths in `packages` and `extensions` starting with ~/ are resolved to
    # the user's home directory. The file is read-only; manage it here
    # instead of editing settings.json or running `pi install`.
    settings = mkOpt attrs {
      defaultProvider = "openai-codex";
      defaultModel = "gpt-5.5";
      packages = [
        "~/Code/llm-agents"
        "~/Code/llm-agents-private"
        "~/Code/attractor"
        "${pkgs.my.pi-sub-bar}/lib/pi-sub-bar"
      ];
      theme = "catppuccin-mocha";
      defaultThinkingLevel = "xhigh";
      hideThinkingBlock = true;
      enabledModels = [
        "openai-codex/gpt-5.5:xhigh"
        "anthropic/claude-sonnet-4-6:high"
        "anthropic/claude-opus-4-6:high"
        "openai-codex/gpt-5.4:high"
      ];
      branchSummary = {
        skipPrompt = true;
      };
    };

    # Design Studio settings written to ~/.pi/agent/design-studio.json.
    # See llm-agents/pi/design-studio/README.md for schema.
    designStudio = mkOpt attrs { };
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        packages = [
          pkgs.llm-agents.pi
        ];

        file = mkMerge [
          (mkIf (cfg.settings != { }) {
            ".pi/agent/settings.json".source = settingsFile;
          })
          (mkIf (cfg.designStudio != { }) {
            ".pi/agent/design-studio.json".source = designStudioFile;
          })
        ];
      };

      programs.fish.functions.piws = ''
        if test (count $argv) -ne 1
            echo "Usage: piws <workspace-name>"
            return 1
        end

        set -l ws_name $argv[1]
        set -l repo_root (jj root 2>/dev/null)

        if test $status -ne 0
            echo "Error: not in a jj repository"
            return 1
        end

        set -l parent_dir (dirname $repo_root)
        set -l repo_name (basename $repo_root)
        set -l ws_dir "$parent_dir/$repo_name-ws-$ws_name"

        if test -d "$ws_dir"
            cd "$ws_dir"
            pi
        else
            jj workspace add --name "$ws_name" "$ws_dir"
            and cd "$ws_dir"
            and pi
        end
      '';
    };
  };
}
