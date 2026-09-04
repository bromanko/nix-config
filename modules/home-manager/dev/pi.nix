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
      defaultModel = "gpt-5.6-sol";
      packages = [
        {
          source = "~/Code/llm-agents";
          extensions = [
            "!pi/ci-guard/extensions/**"
            "!pi/live-edit/extensions/**"
          ];
        }
        "~/Code/llm-agents-private"
        "~/Code/attractor"
        "${pkgs.my.pi-codex-fast-mode}/lib/pi-codex-fast-mode"
        "${pkgs.my.pi-sub-bar}/lib/pi-sub-bar"
      ];
      theme = "catppuccin-mocha";
      defaultThinkingLevel = "xhigh";
      hideThinkingBlock = true;
      enabledModels = [
        "openai-codex/gpt-6-astra:medium"
        "openai-codex/gpt-5.6-sol:xhigh"
        "openai-codex/gpt-6-astra:xhigh"
        "openai-codex/gpt-6-astra:max"
        "openai-codex/gpt-5.6-sol:xhigh"
        "openai-codex/gpt-5.6-sol:max"
        "openai-codex/gpt-5.6-terra:xhigh"
        "openai-codex/gpt-5.6-luna:xhigh"
        "anthropic/claude-opus-5:max"
        "anthropic/claude-fable-5-1:xhigh"
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

    # Model registry written to ~/.pi/agent/models.json.
    # Remove custom models once they are included in Pi's built-in catalog.
    models = mkOpt attrs {
      # Remove once Astra is included in Pi's built-in model catalog.
      providers.openai-codex.models = [
        {
          id = "gpt-6-astra";
          name = "GPT-6 Astra";
          api = "openai-codex-responses";
          baseUrl = "https://chatgpt.com/backend-api";
          reasoning = true;
          thinkingLevelMap = {
            off = null;
            minimal = null;
            xhigh = "xhigh";
            max = "max";
          };
          input = [
            "text"
            "image"
          ];
          contextWindow = 272000;
          maxTokens = 128000;
          compat = {
            supportsOpenAIGrammarTools = true;
            supportsAdditionalTools = true;
            supportsToolSearch = true;
          };
        }
      ];

      # Pi 0.84.x identifies OAuth requests as Claude Code 2.1.75, which
      # Anthropic rejects for Fable 5.1. Override the stale built-in header.
      providers.anthropic.headers."user-agent" = "claude-cli/2.1.257";
      providers.anthropic.models = [
        {
          id = "claude-fable-5-1";
          name = "Claude Fable 5.1";
          reasoning = true;
          thinkingLevelMap = {
            off = null;
            xhigh = "xhigh";
            max = "max";
          };
          input = [
            "text"
            "image"
          ];
          contextWindow = 1000000;
          maxTokens = 128000;
          cost = {
            input = 10;
            output = 50;
            cacheRead = 0.25;
            cacheWrite = 12.5;
          };
          compat = {
            forceAdaptiveThinking = true;
            supportsTemperature = false;
            supportsStrictTools = true;
          };
        }
        {
          id = "claude-opus-5";
          name = "Claude Opus 5";
          reasoning = true;
          thinkingLevelMap = {
            xhigh = "xhigh";
            max = "max";
          };
          input = [
            "text"
            "image"
          ];
          contextWindow = 1000000;
          maxTokens = 128000;
          cost = {
            input = 5;
            output = 25;
            cacheRead = 0.5;
            cacheWrite = 6.25;
          };
          compat = {
            forceAdaptiveThinking = true;
            supportsTemperature = false;
            supportsStrictTools = true;
          };
        }
      ];
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
          {
            ".pi/agent/AGENTS.md".source = ./pi/AGENTS.md;
          }
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
