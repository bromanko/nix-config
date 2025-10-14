{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.autoraise;
in
{
  options.modules.desktop.apps.autoraise = with types; {
    enable = mkBoolOpt false;

    delay = mkOption {
      type = int;
      default = 2;
      description = "Raise delay in polling units";
    };

    focusDelay = mkOption {
      type = int;
      default = 1;
      description = "Focus delay in polling units";
    };

    pollMillis = mkOption {
      type = int;
      default = 50;
      description = "Mouse position polling frequency in milliseconds (20-50ms recommended)";
    };

    warpX = mkOption {
      type = float;
      default = 0.5;
      description = "Mouse warping factor for X axis (0-1 range)";
    };

    warpY = mkOption {
      type = float;
      default = 0.5;
      description = "Mouse warping factor for Y axis (0-1 range)";
    };

    ignoreApps = mkOption {
      type = listOf str;
      default = [ ];
      description = "List of application names to exclude from focus/raise";
      example = [
        "Emacs"
        "Terminal"
      ];
    };

    altTaskSwitcher = mkOption {
      type = bool;
      default = false;
      description = "Enable support for 3rd party task switchers";
    };

    verbose = mkOption {
      type = bool;
      default = false;
      description = "Enable detailed logging";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.autoraise ];

    launchd.user.agents.autoraise = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.autoraise}/bin/AutoRaise"
          "-delay"
          (toString cfg.delay)
          "-focusDelay"
          (toString cfg.focusDelay)
          "-pollMillis"
          (toString cfg.pollMillis)
          "-warpX"
          (toString cfg.warpX)
          "-warpY"
          (toString cfg.warpY)
        ]
        ++ (optionals (cfg.ignoreApps != [ ]) [
          "-ignoreApps"
          (concatStringsSep "," cfg.ignoreApps)
        ])
        ++ (optional cfg.altTaskSwitcher "-altTaskSwitcher=true")
        ++ (optional cfg.verbose "-verbose");
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Interactive";
      };
    };
  };
}
