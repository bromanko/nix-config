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
  homeDir = config.users.users.${config.user.name}.home;

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
in
{
  options.modules.dev.pi = with types; {
    enable = mkBoolOpt false;

    # Freeform settings written to ~/.pi/agent/settings.json.
    # Paths in `packages` and `extensions` starting with ~/ are resolved to
    # the user's home directory. The file is read-only; manage it here
    # instead of editing settings.json or running `pi install`.
    settings = mkOpt attrs {
      defaultProvider = "anthropic";
      defaultModel = "claude-opus-4-6";
      packages = [
        "~/Code/llm-agents"
        "~/Code/llm-agents-private"
        "~/Code/attractor"
        "${pkgs.my.pi-sub-bar}/lib/pi-sub-bar"
      ];
      theme = "catppuccin-mocha";
      defaultThinkingLevel = "high";
    };
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        packages = [
          pkgs.llm-agents.pi
        ];

        file = mkIf (cfg.settings != { }) {
          ".pi/agent/settings.json".source = settingsFile;
        };
      };
    };
  };
}
