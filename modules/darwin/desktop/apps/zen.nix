{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.zen;

  setZenIconAppleScript = pkgs.writeText "set-zen-icon.applescript" ''
    use framework "AppKit"
    use scripting additions

    on run argv
      set iconPath to item 1 of argv
      set targetPath to item 2 of argv
      set iconImage to current application's NSImage's alloc()'s initWithContentsOfFile:iconPath
      if iconImage is missing value then error "Could not read icon: " & iconPath
      set ok to current application's NSWorkspace's sharedWorkspace()'s setIcon:iconImage forFile:targetPath options:0
      if (ok as boolean) is false then error "NSWorkspace setIcon failed for " & targetPath
    end run
  '';

  applyZenIcon = pkgs.writeShellScriptBin "apply-zen-icon" ''
    set -euo pipefail

    icon_path=${lib.escapeShellArg cfg.iconPath}
    app_path=${lib.escapeShellArg cfg.appPath}

    if [[ ! -d "$app_path" ]]; then
      echo "Zen app not found at $app_path; skipping icon application." >&2
      exit 0
    fi

    if [[ ! -f "$icon_path" ]]; then
      echo "Zen icon not found at $icon_path; skipping icon application." >&2
      exit 0
    fi

    /usr/bin/osascript ${setZenIconAppleScript} "$icon_path" "$app_path"
    /usr/bin/touch "$app_path"
    echo "Applied Zen icon from $icon_path to $app_path"
  '';
in
{
  options.modules.desktop.apps.zen = with types; {
    enable = mkBoolOpt false;

    iconPath = mkOption {
      type = str;
      default = "${config.nixConfigPath}/configs/zen/icon.icns";
      description = ''
        Absolute path to the ICNS file to apply to Zen.app.

        This is intentionally a string instead of a Nix path so the system can
        build before the icon exists in the working tree. Put the generated icon
        at configs/zen/icon.icns and the activation hook/launchd agent will
        start applying it.
      '';
    };

    appPath = mkOption {
      type = str;
      default = "/Applications/Zen.app";
      description = "Path to the Zen.app bundle installed by Homebrew.";
    };

    watchPaths = mkOption {
      type = listOf str;
      default = [
        "/Applications/Zen.app"
        "${config.nixConfigPath}/configs/zen"
      ];
      description = ''
        Paths watched by launchd to reapply the custom icon after Zen updates or
        the icon file changes.
      '';
    };

    intervalSeconds = mkOption {
      type = ints.positive;
      default = 3600;
      description = "Fallback interval for reapplying the Zen icon.";
    };
  };

  config = mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isDarwin) {
    modules.homebrew.casks = [ "zen" ];

    hm = {
      home.packages = [ applyZenIcon ];

      home.activation.applyZenIcon = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        if ! ${applyZenIcon}/bin/apply-zen-icon; then
          echo "warning: failed to apply Zen icon; launchd agent will retry" >&2
        fi
      '';

      launchd.agents.zen-icon = {
        enable = true;
        config = {
          ProgramArguments = [ "${applyZenIcon}/bin/apply-zen-icon" ];
          RunAtLoad = true;
          WatchPaths = cfg.watchPaths;
          StartInterval = cfg.intervalSeconds;
          StandardOutPath = "${config.hm.home.homeDirectory}/Library/Logs/zen-icon.log";
          StandardErrorPath = "${config.hm.home.homeDirectory}/Library/Logs/zen-icon.log";
          ProcessType = "Background";
        };
      };
    };
  };
}
