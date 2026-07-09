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

  # Package settings support either plain strings or object-form filters.
  # Keep the object form intact while resolving ~/ in its source field.
  resolvePackage =
    p:
    if isString p then
      resolveTildePath p
    else if isAttrs p && p ? source && isString p.source then
      p // { source = resolveTildePath p.source; }
    else
      p;

  claudeCodeUsePackage = "${pkgs.my.pi-claude-code-use}/lib/pi-claude-code-use";
  effectiveExtraPackages =
    cfg.extraPackages ++ optional cfg.claudeCodeUse.enable claudeCodeUsePackage;

  hasPackages = (cfg.settings ? packages) || effectiveExtraPackages != [ ];
  configuredPackages = cfg.settings.packages or [ ];

  resolvedSettings =
    cfg.settings
    // (optionalAttrs hasPackages {
      packages = map resolvePackage (configuredPackages ++ effectiveExtraPackages);
    })
    // (optionalAttrs (cfg.settings ? extensions) {
      extensions = map resolveTildePath cfg.settings.extensions;
    });

  settingsFile = pkgs.writeText "pi-settings.json" (builtins.toJSON resolvedSettings);
  modelsFile = pkgs.writeText "pi-models.json" (builtins.toJSON cfg.models);
  designStudioFile = pkgs.writeText "pi-design-studio.json" (builtins.toJSON cfg.designStudio);
  claudeCodeUseConfigFile = pkgs.writeText "pi-claude-code-use.json" (
    builtins.toJSON {
      inherit (cfg.claudeCodeUse) toolAliases;
    }
  );
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
        {
          source = "~/Code/llm-agents";
          extensions = [
            "!pi/ci-guard/extensions/**"
          ];
        }
        "~/Code/llm-agents-private"
        "~/Code/attractor"
        "${pkgs.my.pi-sub-bar}/lib/pi-sub-bar"
      ];
      theme = "catppuccin-mocha";
      defaultThinkingLevel = "xhigh";
      hideThinkingBlock = true;
      enabledModels = [
        # :minimal maps to backend ultra for gpt-5.6-sol in models.json.
        "openai-codex/gpt-5.6-sol:minimal"
        "openai-codex/gpt-5.6-sol:xhigh"
        "openai-codex/gpt-5.6-terra:xhigh"
        "openai-codex/gpt-5.6-luna:xhigh"
        "openai-codex/gpt-5.5:xhigh"
        "anthropic/claude-fable-5:xhigh"
        "anthropic/claude-opus-4-8:xhigh"
        "anthropic/claude-opus-4-6:xhigh"
      ];
      branchSummary = {
        skipPrompt = true;
      };
    };

    # Additional Pi packages appended to settings.packages.
    # Useful for host-specific packages without replacing the shared defaults.
    extraPackages = mkOpt (listOf (oneOf [
      str
      attrs
    ])) [ ];

    # Anthropic OAuth compatibility package for Claude Code-style subscription use.
    # Adds the pi-claude-code-use package and writes its tool alias config.
    claudeCodeUse = {
      enable = mkBoolOpt false;
      toolAliases = mkOpt (listOf (listOf str)) [
        [
          "web_search"
          "mcp__brave__web_search"
        ]
        [
          "fetch"
          "mcp__web__fetch"
        ]
        [
          "find"
          "mcp__filesystem__find"
        ]
        [
          "lsp"
          "mcp__lsp__code_intelligence"
        ]
        [
          "design_checkpoint"
          "mcp__design_studio__checkpoint"
        ]
        [
          "autoresearch_log"
          "mcp__autoresearch__log"
        ]
      ];
    };

    # Freeform custom model registry written to ~/.pi/agent/models.json.
    # Pi keeps built-in provider models and upserts these by id.
    models = mkOpt attrs {
      providers = {
        "openai-codex" = {
          models = [
            {
              id = "gpt-5.6-sol";
              name = "GPT-5.6 Sol";
              reasoning = true;
              # Pi does not expose max/ultra as native thinking levels yet.
              # Use :minimal as the UI/CLI alias for backend ultra, while
              # keeping :xhigh mapped to backend xhigh.
              thinkingLevelMap = {
                minimal = "ultra";
                xhigh = "xhigh";
              };
              input = [
                "text"
                "image"
              ];
              contextWindow = 372000;
              maxTokens = 128000;
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
            }
            {
              id = "gpt-5.6-terra";
              name = "GPT-5.6 Terra";
              reasoning = true;
              thinkingLevelMap = {
                minimal = "low";
                xhigh = "xhigh";
              };
              input = [
                "text"
                "image"
              ];
              contextWindow = 372000;
              maxTokens = 128000;
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
            }
            {
              id = "gpt-5.6-luna";
              name = "GPT-5.6 Luna";
              reasoning = true;
              thinkingLevelMap = {
                minimal = "low";
                xhigh = "xhigh";
              };
              input = [
                "text"
                "image"
              ];
              contextWindow = 372000;
              maxTokens = 128000;
              cost = {
                input = 0;
                output = 0;
                cacheRead = 0;
                cacheWrite = 0;
              };
            }
          ];
        };
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
          (mkIf (resolvedSettings != { }) {
            ".pi/agent/settings.json".source = settingsFile;
          })
          (mkIf (cfg.models != { }) {
            ".pi/agent/models.json".source = modelsFile;
          })
          (mkIf (cfg.designStudio != { }) {
            ".pi/agent/design-studio.json".source = designStudioFile;
          })
          (mkIf cfg.claudeCodeUse.enable {
            ".pi/agent/extensions/pi-claude-code-use.json".source = claudeCodeUseConfigFile;
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
