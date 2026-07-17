{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.modules.dev.lima.sshAgentBridge;
  userHome = "/Users/${config.user.name}";
  identityFiles = map (
    identityFile: if lib.hasPrefix "/" identityFile then identityFile else "${userHome}/${identityFile}"
  ) cfg.identityFiles;
  identityFileArgs = lib.concatMapStringsSep " " lib.escapeShellArg identityFiles;
  sshConfig = "${userHome}/.lima/${cfg.instance}/ssh.config";
  limaHost = "lima-${cfg.instance}";
  guestScript = ''
    set -euo pipefail
    install -d -m 0700 "$HOME/.ssh"
    ln -sfn "$SSH_AUTH_SOCK" "$HOME/.ssh/${cfg.guestSocketName}"
    exec sleep 2147483647
  '';
  remoteCommand = "exec bash -lc ${lib.escapeShellArg guestScript}";
  bridge = pkgs.writeShellApplication {
    name = "lima-ssh-agent-bridge";
    runtimeInputs = [ pkgs.openssh ];
    text = ''
      ssh_config=${lib.escapeShellArg sshConfig}
      identity_files=( ${identityFileArgs} )
      bridge_pid=""
      agent_started=0

      cleanup() {
        trap - EXIT HUP INT TERM

        if [[ -n "$bridge_pid" ]]; then
          kill "$bridge_pid" 2>/dev/null || true
          wait "$bridge_pid" 2>/dev/null || true
        fi

        if [[ "$agent_started" -eq 1 ]]; then
          ssh-agent -k >/dev/null 2>&1 || true
        fi
      }
      trap cleanup EXIT HUP INT TERM

      [[ -r "$ssh_config" ]]
      for identity_file in "''${identity_files[@]}"; do
        [[ -r "$identity_file" ]]
      done

      eval "$(ssh-agent -s)" >/dev/null
      agent_started=1
      for identity_file in "''${identity_files[@]}"; do
        ssh-add "$identity_file" </dev/null >/dev/null 2>&1
      done

      ssh \
        -F "$ssh_config" \
        -o BatchMode=yes \
        -o ControlMaster=no \
        -o ControlPath=none \
        -o ControlPersist=no \
        -o ForwardAgent=yes \
        -o ServerAliveInterval=15 \
        -o ServerAliveCountMax=3 \
        -o SetEnv=LIMA_SSH_AGENT_BRIDGE=1 \
        ${lib.escapeShellArg limaHost} \
        ${lib.escapeShellArg remoteCommand} \
        >/dev/null 2>&1 &
      bridge_pid=$!
      wait "$bridge_pid"
    '';
  };
in
{
  options.modules.dev.lima.sshAgentBridge = {
    enable = lib.mkEnableOption "a durable, least-privilege SSH-agent bridge into Lima";

    instance = lib.mkOption {
      type = lib.types.str;
      default = "lima-dev";
      description = "Name of the Lima instance that receives the agent bridge";
    };

    identityFiles = lib.mkOption {
      type = lib.types.listOf lib.types.str;
      default = [ ];
      description = ''
        Host identity files loaded into the isolated forwarding agent. Relative
        paths are resolved from the configured Darwin user's home directory.
      '';
    };

    guestSocketName = lib.mkOption {
      type = lib.types.strMatching "[A-Za-z0-9._-]+";
      default = "host-agent.sock";
      description = "Socket name created under the guest user's ~/.ssh directory";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = cfg.identityFiles != [ ];
        message = "modules.dev.lima.sshAgentBridge.identityFiles must not be empty";
      }
    ];

    launchd.user.agents.lima-ssh-agent-bridge = {
      serviceConfig = {
        ProgramArguments = [ "${bridge}/bin/lima-ssh-agent-bridge" ];
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Background";
        ThrottleInterval = 15;
        StandardOutPath = "/dev/null";
        StandardErrorPath = "/dev/null";
      };
    };
  };
}
