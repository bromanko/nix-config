{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.context-lens;
  homeDir = "/Users/${config.user.name}";
  dataDir = "${homeDir}/.context-lens";
in
{
  options.modules.dev.context-lens = with types; {
    enable = mkBoolOpt false;

    proxyPort = mkOption {
      type = types.port;
      default = 4040;
      description = "Port for the Context Lens reverse proxy";
    };

    uiPort = mkOption {
      type = types.port;
      default = 4041;
      description = "Port for the Context Lens analysis web UI";
    };

    privacy = mkOption {
      type = types.enum [
        "minimal"
        "standard"
        "full"
      ];
      default = "standard";
      description = "Privacy level for captured data (minimal|standard|full)";
    };
  };

  config = mkIf cfg.enable {
    # Context Lens runs as two launchd services: a reverse proxy that
    # captures LLM API requests and an analysis server that serves the
    # web UI. The secret-proxy (mitmproxy) redirects LLM API traffic
    # through the Context Lens proxy after injecting secrets, so the
    # full chain is: tool → secret-proxy → context-lens → real API.

    environment.systemPackages = [ pkgs.my.context-lens ];

    # Rotate launchd log files: keep 3 archives, rotate at 1 MB.
    #
    # Two launchd-specific concerns (same as secret-proxy):
    #
    # 1. Ownership: newsyslog runs as root and creates replacement files
    #    as root:admin by default.  The services run as the primary user,
    #    so we set owner:group explicitly.  Without this the service cannot
    #    write to the new log file after rotation and exits immediately.
    #
    # 2. Stale file descriptors: launchd holds stdout/stderr fds open for
    #    the process lifetime.  After newsyslog renames the file, the
    #    process keeps writing to the old (renamed) inode.  We use N (no
    #    signal, no compression) so the rotated file remains readable.
    environment.etc."newsyslog.d/context-lens.conf".text = ''
      # logfile                                owner:group        mode count size when flags
      ${dataDir}/proxy.log                     ${config.user.name}:staff 644  3     1024 *    N
      ${dataDir}/proxy.err                     ${config.user.name}:staff 644  3     1024 *    N
      ${dataDir}/analysis.log                  ${config.user.name}:staff 644  3     1024 *    N
      ${dataDir}/analysis.err                  ${config.user.name}:staff 644  3     1024 *    N
    '';

    launchd.user.agents.context-lens-proxy = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.my.context-lens}/bin/context-lens-proxy"
        ];
        EnvironmentVariables = {
          CONTEXT_LENS_PROXY_PORT = toString cfg.proxyPort;
          CONTEXT_LENS_BIND_HOST = "127.0.0.1";
          CONTEXT_LENS_PRIVACY = cfg.privacy;
          CONTEXT_LENS_ALLOW_TARGET_OVERRIDE = "1";
          CONTEXT_LENS_CAPTURE_DIR = "${dataDir}/captures";
          CONTEXT_LENS_NO_UPDATE_CHECK = "1";
        };
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${dataDir}/proxy.log";
        StandardErrorPath = "${dataDir}/proxy.err";
        WorkingDirectory = dataDir;
      };
    };

    launchd.user.agents.context-lens-analysis = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.my.context-lens}/bin/context-lens-analysis"
        ];
        EnvironmentVariables = {
          CONTEXT_LENS_ANALYSIS_PORT = toString cfg.uiPort;
          CONTEXT_LENS_BIND_HOST = "127.0.0.1";
          CONTEXT_LENS_PRIVACY = cfg.privacy;
          CONTEXT_LENS_CAPTURE_DIR = "${dataDir}/captures";
          CONTEXT_LENS_NO_UPDATE_CHECK = "1";
        };
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${dataDir}/analysis.log";
        StandardErrorPath = "${dataDir}/analysis.err";
        WorkingDirectory = dataDir;
      };
    };
  };
}
