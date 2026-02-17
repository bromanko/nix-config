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
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.mitmproxy ];

    hm = {
      xdg.configFile = {
        "secret-proxy/secret_proxy.py".source =
          config.hm.lib.file.mkNixConfigSymlink "/configs/secret-proxy/secret_proxy.py";
      };
    };

    launchd.user.agents.secret-proxy = {
      serviceConfig = {
        ProgramArguments = [
          "${pkgs.mitmproxy}/bin/mitmdump"
          "--listen-host"
          "127.0.0.1"
          "--listen-port"
          (toString cfg.port)
          "-s"
          "${configDir}/secret_proxy.py"
          "--set"
          "secret_proxy_env_file=${configDir}/secrets.env"
          "--set"
          "secret_proxy_namespace_dir=${namespaceDir}"
          "--set"
          "block_global=false"
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
