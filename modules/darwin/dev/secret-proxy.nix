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
  namespacePaths = map (namespace: "${namespaceDir}/${namespace}") cfg.namespaces;
  secretProxyDirs = [
    configDir
    namespaceDir
  ]
  ++ namespacePaths;
  ensureSecretProxyDirs = concatMapStringsSep "\n" (dir: ''
    install -d -m 0700 -o ${escapeShellArg config.user.name} -g staff ${escapeShellArg dir}
  '') secretProxyDirs;
  providerArgs =
    if cfg.provider == "environmentFiles" then
      [
        "--set"
        "secret_proxy_provider=environment-files"
        "--set"
        "secret_proxy_env_file=${configDir}/secrets.env"
        "--set"
        "secret_proxy_namespace_dir=${namespaceDir}"
        "--set"
        "secret_proxy_file_read_timeout=${toString cfg.environmentFiles.readTimeoutSeconds}"
      ]
    else
      [
        "--set"
        "secret_proxy_provider=service-account"
        "--set"
        "secret_proxy_op_cli=${cfg.serviceAccount.package}/bin/op"
        "--set"
        "secret_proxy_service_account_token_file=${cfg.serviceAccount.tokenFile}"
        "--set"
        "secret_proxy_environment_map=${builtins.toJSON cfg.serviceAccount.environments}"
        "--set"
        "secret_proxy_cache_ttl=${toString cfg.serviceAccount.cacheTtlSeconds}"
        "--set"
        "secret_proxy_command_timeout=${toString cfg.serviceAccount.commandTimeoutSeconds}"
      ];
  limaHome = "${homeDir}/.lima";

  # Script that maintains the SSH reverse tunnel to a Lima VM.
  # Uses Lima's existing SSH control socket so no extra auth is needed.
  tunnelScript = pkgs.writeShellScript "secret-proxy-tunnel" ''
    set -euo pipefail

    LIMA_SSH_CONFIG="${limaHome}/${cfg.limaInstance}/ssh.config"
    LIMA_SOCKET="${limaHome}/${cfg.limaInstance}/ssh.sock"
    LIMA_HOST="lima-${cfg.limaInstance}"
    PORT="${toString cfg.port}"

    log() {
      printf '%s secret-proxy-tunnel: %s\n' "$(date -u '+%Y-%m-%dT%H:%M:%SZ')" "$*"
    }

    control_master_ready() {
      [ -f "$LIMA_SSH_CONFIG" ] \
        && [ -S "$LIMA_SOCKET" ] \
        && /usr/bin/ssh -F "$LIMA_SSH_CONFIG" -O check "$LIMA_HOST" >/dev/null 2>&1
    }

    guest_proxy_healthy() {
      # SSH evaluates remote commands with the guest's login shell, which may
      # be Fish. Keep the outer command shell-agnostic and perform the proxy
      # health check explicitly in Bash. A TCP-only check is not enough: after
      # the host proxy restarts, sshd can keep a stale remote listener that
      # accepts and then resets connections.
      /usr/bin/ssh \
        -F "$LIMA_SSH_CONFIG" \
        -o BatchMode=yes \
        -o ConnectTimeout=5 \
        -o ConnectionAttempts=1 \
        "$LIMA_HOST" \
        "bash -lc 'exec 3<>/dev/tcp/127.0.0.1/$PORT || exit 1; printf \"GARBAGE\\r\\n\\r\\n\" >&3; IFS= read -r -t 5 line <&3 || exit 1; [[ \"\$line\" == HTTP/* ]]'" \
        >/dev/null 2>&1
    }

    cancel_forward() {
      /usr/bin/ssh \
        -F "$LIMA_SSH_CONFIG" \
        -O cancel \
        -R "127.0.0.1:$PORT:127.0.0.1:$PORT" \
        "$LIMA_HOST" \
        >/dev/null 2>&1 || true
    }

    establish_forward() {
      /usr/bin/ssh \
        -F "$LIMA_SSH_CONFIG" \
        -o ExitOnForwardFailure=yes \
        -O forward \
        -R "127.0.0.1:$PORT:127.0.0.1:$PORT" \
        "$LIMA_HOST"
    }

    log "monitoring reverse tunnel on guest 127.0.0.1:$PORT"

    while true; do
      until control_master_ready; do
        sleep 5
      done

      if guest_proxy_healthy; then
        sleep 10
        continue
      fi

      log "guest proxy health check failed; recreating reverse forward"
      cancel_forward
      if establish_forward; then
        sleep 1
        if guest_proxy_healthy; then
          log "reverse tunnel established"
        else
          log "reverse tunnel command succeeded but proxy health check still fails"
          sleep 5
        fi
      else
        log "reverse tunnel setup failed; retrying"
        sleep 5
      fi
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

    provider = mkOption {
      type = types.enum [
        "environmentFiles"
        "serviceAccount"
      ];
      default = "environmentFiles";
      description = "1Password Environment provider used by secret-proxy";
    };

    environmentFiles.readTimeoutSeconds = mkOption {
      type = types.ints.positive;
      default = 15;
      description = "Maximum time to wait for 1Password local Environment approval";
    };

    serviceAccount = {
      tokenFile = mkOption {
        type = types.str;
        default = "${homeDir}/.config/age/secrets/secret-proxy-service-account-token";
        description = "Runtime path to the Homeage-decrypted service-account token";
      };

      environments = mkOption {
        type = types.attrsOf types.str;
        default = { };
        example = {
          default = "environment-id";
          scherzo = "environment-id";
        };
        description = ''
          Mapping from placeholder namespace to 1Password Environment ID.
          The unqualified placeholder namespace uses the key "default".
          Unlisted namespaces fail closed.
        '';
      };

      cacheTtlSeconds = mkOption {
        type = types.ints.unsigned;
        default = 300;
        description = "Time to cache fetched Environment values in host memory";
      };

      commandTimeoutSeconds = mkOption {
        type = types.ints.positive;
        default = 15;
        description = "Maximum time to wait for 1Password CLI";
      };

      package = mkOption {
        type = types.package;
        default = pkgs.my."1password-cli-beta";
        description = "1Password CLI package with Environment support";
      };
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
        List of namespace names available to secret-proxy. Environment-file
        mode mounts each under ~/.config/secret-proxy/namespaces/<name>/secrets.env.
        Service-account mode resolves configured Environment IDs instead.
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
    assertions = optionals (cfg.provider == "serviceAccount") [
      {
        assertion = cfg.serviceAccount.tokenFile != "";
        message = "modules.dev.secret-proxy.serviceAccount.tokenFile must not be empty";
      }
      {
        assertion = (cfg.serviceAccount.environments.default or "") != "";
        message = ''
          modules.dev.secret-proxy.serviceAccount.environments.default must contain
          the default 1Password Environment ID
        '';
      }
    ];

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

    # Keep fallback 1Password Environment destination directories available.
    # This also preserves a one-option rollback from service-account mode.
    system.activationScripts.postActivation.text = ensureSecretProxyDirs;

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
        ]
        ++ providerArgs
        ++ [
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
