{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.dealmail;

  # Script that sources secrets and runs dealmail
  dealmailRunner = pkgs.writeShellScript "dealmail-runner" ''
    set -euo pipefail

    LOCKFILE="${config.hm.home.homeDirectory}/Library/Application Support/dealmail/dealmail.lock"

    # Check for existing lock file
    if [ -f "$LOCKFILE" ]; then
      PID=$(cat "$LOCKFILE")
      if kill -0 "$PID" 2>/dev/null; then
        echo "Dealmail is already running (PID: $PID). Exiting."
        exit 0
      else
        echo "Stale lock file found. Removing."
        rm -f "$LOCKFILE"
      fi
    fi

    # Create lock file
    echo $$ > "$LOCKFILE"
    trap "rm -f '$LOCKFILE'" EXIT

    # Source secrets (environment variables)
    if [ -f "${config.hm.homeage.mount}/dealmail-secrets" ]; then
      source "${config.hm.homeage.mount}/dealmail-secrets"
    else
      echo "ERROR: Dealmail secrets file not found at ${config.hm.homeage.mount}/dealmail-secrets"
      rm -f "$LOCKFILE"
      exit 1
    fi

    # Run dealmail process-deals
    ${inputs.dealmail.packages.${pkgs.system}.process-deals}/bin/process-deals
  '';

  # Script that sources secrets and runs emails-to-feed
  emailsToFeedRunner = pkgs.writeShellScript "emails-to-feed-runner" ''
    set -euo pipefail

    LOCKFILE="${config.hm.home.homeDirectory}/Library/Application Support/dealmail/emails-to-feed.lock"

    # Check for existing lock file
    if [ -f "$LOCKFILE" ]; then
      PID=$(cat "$LOCKFILE")
      if kill -0 "$PID" 2>/dev/null; then
        echo "Emails-to-feed is already running (PID: $PID). Exiting."
        exit 0
      else
        echo "Stale lock file found. Removing."
        rm -f "$LOCKFILE"
      fi
    fi

    # Create lock file
    echo $$ > "$LOCKFILE"
    trap "rm -f '$LOCKFILE'" EXIT

    # Source secrets (environment variables)
    if [ -f "${config.hm.homeage.mount}/dealmail-secrets" ]; then
      source "${config.hm.homeage.mount}/dealmail-secrets"
    else
      echo "ERROR: Dealmail secrets file not found at ${config.hm.homeage.mount}/dealmail-secrets"
      rm -f "$LOCKFILE"
      exit 1
    fi

    # Run emails-to-feed
    ${inputs.dealmail.packages.${pkgs.system}.emails-to-feed}/bin/emails-to-feed
  '';
in
{
  options.modules.desktop.apps.dealmail = {
    enable = mkBoolOpt false;

    processDeals = {
      enable = mkBoolOpt true;
      intervalMinutes = mkOption {
        type = types.addCheck types.int (n: n > 0 && n <= 60 && (lib.mod 60 n == 0));
        default = 15;
        description = "Interval in minutes to run process-deals (must divide evenly into 60)";
      };
    };

    emailsToFeed = {
      enable = mkBoolOpt true;
      startMinute = mkOption {
        type = types.int;
        default = 30;
        description = "Minute of each hour to run emails-to-feed (0-59)";
      };
    };
  };

  config = mkIf cfg.enable {
    hm = {
      home.packages = with pkgs; [
        inputs.dealmail.packages.${pkgs.system}.default
      ];

      # Configure homeage secret for dealmail
      homeage.file.dealmail-secrets = {
        source = ../../../../configs/dealmail/dealmail-secrets.age;
      };

      # Create working directory for dealmail
      home.activation.createDealmailDir = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
        mkdir -p "${config.hm.home.homeDirectory}/Library/Application Support/dealmail"
      '';

      # Launchd agent for process-deals scheduled execution
      launchd.agents.dealmail-process-deals = mkIf cfg.processDeals.enable {
        enable = true;
        config = {
          ProgramArguments = [ "${dealmailRunner}" ];
          StartCalendarInterval = builtins.genList (i: { Minute = i * cfg.processDeals.intervalMinutes; }) (
            60 / cfg.processDeals.intervalMinutes
          );
          WorkingDirectory = "${config.hm.home.homeDirectory}/Library/Application Support/dealmail";
          StandardOutPath = "${config.hm.home.homeDirectory}/Library/Logs/dealmail-process-deals.log";
          StandardErrorPath = "${config.hm.home.homeDirectory}/Library/Logs/dealmail-process-deals-error.log";
          KeepAlive = false;
          ProcessType = "Background";
        };
      };

      # Launchd agent for emails-to-feed scheduled execution
      launchd.agents.dealmail-emails-to-feed = mkIf cfg.emailsToFeed.enable {
        enable = true;
        config = {
          ProgramArguments = [ "${emailsToFeedRunner}" ];
          StartCalendarInterval = [ { Minute = cfg.emailsToFeed.startMinute; } ];
          WorkingDirectory = "${config.hm.home.homeDirectory}/Library/Application Support/dealmail";
          StandardOutPath = "${config.hm.home.homeDirectory}/Library/Logs/dealmail-emails-to-feed.log";
          StandardErrorPath = "${config.hm.home.homeDirectory}/Library/Logs/dealmail-emails-to-feed-error.log";
          KeepAlive = false;
          ProcessType = "Background";
        };
      };
    };
  };
}
