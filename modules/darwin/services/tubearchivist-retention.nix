{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.services.tubearchivistRetention;
  user = config.user.name;
  group = "staff";
  gib = 1024 * 1024 * 1024;
  tokenDir = builtins.dirOf cfg.tokenFile;
  logFile = "${cfg.stateDir}/retention.log";
  errorLog = "${cfg.stateDir}/retention.err";
  lockFile = "${cfg.stateDir}/retention.lock";
  dockerHost = "unix:///Users/${user}/.docker/run/docker.sock";
  retentionCommand = escapeShellArgs [
    "${pkgs.my.tubearchivist-retention}/bin/tubearchivist-retention"
    "--media-dir"
    cfg.mediaDir
    "--base-url"
    cfg.baseUrl
    "--token-file"
    cfg.tokenFile
    "--max-bytes"
    (toString (cfg.maximumGiB * gib))
    "--target-bytes"
    (toString (cfg.targetGiB * gib))
    "--lock-file"
    lockFile
  ];
  runner = pkgs.writeShellScript "tubearchivist-retention-run" ''
    if ${retentionCommand}; then
      exit 0
    fi

    echo "retention cleanup failed while over limit; stopping ${cfg.containerName}" >&2
    ${pkgs.docker}/bin/docker --host ${escapeShellArg dockerHost} stop \
      ${escapeShellArg cfg.containerName} >&2 || true
    exit 1
  '';
in
{
  options.modules.services.tubearchivistRetention = with types; {
    enable = mkBoolOpt false;

    mediaDir = mkOption {
      type = str;
      default = "/Users/Shared/media-server/youtube";
      description = "TubeArchivist media directory whose size is limited.";
    };

    stateDir = mkOption {
      type = str;
      default = "/Users/Shared/media-server/retention";
      description = "Runtime logs and lock file for the retention job.";
    };

    tokenFile = mkOption {
      type = str;
      default = "/Users/Shared/media-server/secrets/tubearchivist-api-token";
      description = "Runtime-only file containing the TubeArchivist API token.";
    };

    baseUrl = mkOption {
      type = str;
      default = "http://localhost:8000";
      description = "TubeArchivist API base URL.";
    };

    containerName = mkOption {
      type = str;
      default = "tubearchivist";
      description = "Container to stop when over-limit cleanup fails.";
    };

    maximumGiB = mkOption {
      type = ints.positive;
      default = 200;
      description = "Size that triggers retention cleanup, in GiB.";
    };

    targetGiB = mkOption {
      type = ints.positive;
      default = 180;
      description = "Low-water size after cleanup, in GiB.";
    };

    intervalSeconds = mkOption {
      type = ints.positive;
      default = 3600;
      description = "Seconds between retention checks.";
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.targetGiB < cfg.maximumGiB;
        message = "TubeArchivist retention targetGiB must be below maximumGiB.";
      }
    ];

    environment.systemPackages = [ pkgs.my.tubearchivist-retention ];

    system.activationScripts.postActivation.text = mkAfter ''
      echo "creating TubeArchivist retention directories..."
      /usr/bin/install -d -o ${escapeShellArg user} -g ${escapeShellArg group} -m 0750 \
        ${escapeShellArg cfg.stateDir} ${escapeShellArg tokenDir}
    '';

    environment.etc."newsyslog.d/tubearchivist-retention.conf".text = ''
      # logfile                                owner:group        mode count size when flags
      ${logFile}                               ${user}:${group} 640  3     1024 *    N
      ${errorLog}                              ${user}:${group} 640  3     1024 *    N
    '';

    launchd.user.agents.tubearchivist-retention = {
      serviceConfig = {
        ProgramArguments = [ "${runner}" ];
        RunAtLoad = true;
        StartInterval = cfg.intervalSeconds;
        ProcessType = "Background";
        LowPriorityIO = true;
        Nice = 10;
        StandardOutPath = logFile;
        StandardErrorPath = errorLog;
      };
    };
  };
}
