{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev."secret-proxy";
  secretProxyPkg = pkgs.my.secret-proxy;
  homeDir = "/Users/${config.user.name}";
  configDir = "${homeDir}/.config/secret-proxy";
  namespaceDir = "${configDir}/namespaces";
  limaHome = "${homeDir}/.lima";

  # Script that maintains the SSH reverse tunnel to a Lima VM.
  # Uses Lima's existing SSH control socket so no extra auth is needed.
  tunnelScript = pkgs.writeShellScript "secret-proxy-tunnel" ''
    set -euo pipefail

    LIMA_SSH_CONFIG="${limaHome}/${cfg.limaInstance}/ssh.config"
    LIMA_HOST="lima-${cfg.limaInstance}"
    PORT="${toString cfg.port}"

    # Wait for Lima SSH config to exist (VM might not be started yet)
    while [ ! -f "$LIMA_SSH_CONFIG" ]; do
      sleep 5
    done

    # Wait for the SSH control socket (VM must be running)
    while [ ! -S "${limaHome}/${cfg.limaInstance}/ssh.sock" ]; do
      sleep 5
    done

    # Set up the reverse forward using the existing control connection.
    # -O forward uses the existing ControlMaster — no new SSH session needed.
    # If it fails (e.g., VM rebooted), retry after a delay.
    while true; do
      if /usr/bin/ssh -F "$LIMA_SSH_CONFIG" -O forward -R "$PORT:127.0.0.1:$PORT" "$LIMA_HOST" 2>/dev/null; then
        # Forward established. Wait until the control socket disappears (VM stopped).
        while [ -S "${limaHome}/${cfg.limaInstance}/ssh.sock" ]; do
          sleep 10
        done
      fi
      sleep 5
    done
  '';
in
{
  options.modules.dev."secret-proxy" = with types; {
    enable = mkBoolOpt false;

    port = mkOption {
      type = types.port;
      default = 17329;
      description = "Port for the secret proxy to listen on";
    };

    limaInstance = mkOption {
      type = types.str;
      default = "lima-dev";
      description = "Name of the Lima instance to tunnel into";
    };

    namespaces = mkOption {
      type = types.listOf types.str;
      default = [ ];
      description = ''
        List of namespace names. Each namespace has its own 1Password
        Environment mounted at ~/.config/secret-proxy/namespaces/<name>/secrets.env.
        Clients reference namespaced secrets with {{namespace:SECRET_NAME}}.
      '';
    };

    contextLens = {
      enable = mkBoolOpt false;

      port = mkOption {
        type = types.port;
        default = 4040;
        description = "Port where Context Lens proxy is listening";
      };
    };
  };

  config = mkIf cfg.enable {
    # mitmproxy pins strict upper bounds on dependencies (e.g. aioquic<=1.2.0)
    # that nixpkgs routinely exceeds with compatible minor/patch bumps.
    # Relax all dependency version constraints and skip tests to avoid
    # build failures from upstream pytest config issues.
    # Also add PyJWT + cryptography for derived secret generators (ES256 JWTs).
    nixpkgs.overlays = [
      (final: prev: {
        mitmproxy = prev.mitmproxy.overridePythonAttrs (old: {
          pythonRelaxDeps = true;
          doCheck = false;
          dependencies = (old.dependencies or [ ]) ++ [
            prev.python3Packages.pyjwt
            prev.python3Packages.cryptography
          ];
        });
      })
    ];

    environment.systemPackages = [ pkgs.mitmproxy ];

    # Rotate launchd log files: keep 3 archives, rotate at 1 MB.
    #
    # Two launchd-specific concerns:
    #
    # 1. Ownership: newsyslog runs as root and creates replacement files
    #    as root:admin by default.  The proxy runs as the primary user,
    #    so we set owner:group explicitly.  Without this the proxy cannot
    #    write to the new log file after rotation and exits immediately.
    #
    # 2. Stale file descriptors: launchd holds stdout/stderr fds open for
    #    the process lifetime.  After newsyslog renames the file, the
    #    process keeps writing to the old (renamed) inode.  There is no
    #    signal we can send to make mitmproxy reopen stdout — only a
    #    service restart fixes it.  We accept that between rotation and
    #    the next restart (rebuild / reboot / manual kickstart) new log
    #    output lands in the rotated file.
    #
    # We use N (no signal) since there's no PID file and no useful
    # signal to send.  We skip J/Z compression so the rotated file
    # (still being written to) remains readable.
    environment.etc."newsyslog.d/secret-proxy.conf".text = ''
      # logfile                                owner:group        mode count size when flags
      ${configDir}/proxy.log                   ${config.user.name}:staff 644  3     1024 *    N
      ${configDir}/proxy.err                   ${config.user.name}:staff 644  3     1024 *    N
      ${configDir}/tunnel.log                  ${config.user.name}:staff 644  3     1024 *    N
      ${configDir}/tunnel.err                  ${config.user.name}:staff 644  3     1024 *    N
    '';

    launchd.user.agents.secret-proxy = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.mitmproxy}/bin/mitmdump"
          "--listen-host"
          "127.0.0.1"
          "--listen-port"
          (toString cfg.port)
          "-s"
          "${secretProxyPkg}/lib/secret-proxy/secret_proxy.py"
          "--set"
          "secret_proxy_env_file=${configDir}/secrets.env"
          "--set"
          "secret_proxy_namespace_dir=${namespaceDir}"
          "--set"
          "block_global=false"
        ]
        ++ optionals cfg.contextLens.enable [
          "--set"
          "context_lens_enabled=true"
          "--set"
          "context_lens_port=${toString cfg.contextLens.port}"
        ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${configDir}/proxy.log";
        StandardErrorPath = "${configDir}/proxy.err";
        WorkingDirectory = configDir;
      };
    };

    launchd.user.agents.secret-proxy-tunnel = {
      serviceConfig = {
        ProgramArguments = [ "${tunnelScript}" ];
        RunAtLoad = true;
        KeepAlive = true;
        StandardOutPath = "${configDir}/tunnel.log";
        StandardErrorPath = "${configDir}/tunnel.err";
      };
    };
  };
}
