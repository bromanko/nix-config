{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.ssh;
  githubBromankoPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzLxgUGkWXC/Hkvuxv4rsJfFYrYq1S16DouIXRXD2Ia";
  githubScherzoAgentPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIv1D8RgQfbHT0lBH6WjBnMSjsNYnH2xbF65cYhU+mQe";
in
{
  options.modules.shell.ssh = with types; {
    enable = mkBoolOpt false;

    forwardedAgentRecovery.enable = mkBoolOpt false;

    envForwarding = {
      enable = mkBoolOpt false;

      hosts = mkOption {
        type = listOf str;
        default = [ ];
        example = [ "gray-area" ];
        description = ''
          SSH host patterns that should receive environment variables from the
          mutable forwarding fragment.
        '';
      };

      configFile = mkOption {
        type = str;
        default = "~/.ssh/env-forwarding.conf";
        description = ''
          SSH client config fragment to include for managed hosts. Keep this as
          a mutable file so SendEnv changes do not require a Home Manager apply.
        '';
      };
    };
  };

  config = mkIf cfg.enable {
    assertions = [
      {
        assertion = !cfg.envForwarding.enable || cfg.envForwarding.hosts != [ ];
        message = "modules.shell.ssh.envForwarding.hosts must not be empty when env forwarding is enabled.";
      }
    ];

    hm = {
      home.file = {
        ".ssh/github-bromanko.pub".text = "${githubBromankoPublicKey}\n";
        ".ssh/github-scherzo-agent.pub".text = "${githubScherzoAgentPublicKey}\n";
      }
      // optionalAttrs cfg.forwardedAgentRecovery.enable {
        # Keep persistent tmux panes on a stable forwarded-agent path. Only
        # promote agents that contain the normal GitHub identity; isolated
        # automation agents must not replace this socket.
        ".ssh/rc" = {
          text = mkDefault ''
            #!/bin/sh
            stable_agent_sock="$HOME/.ssh/agent.sock"
            required_public_key="$HOME/.ssh/github-bromanko.pub"

            if [ "''${LIMA_SSH_AGENT_BRIDGE:-0}" = "1" ] || [ -z "$SSH_AUTH_SOCK" ] || [ ! -S "$SSH_AUTH_SOCK" ] || [ "$SSH_AUTH_SOCK" = "$stable_agent_sock" ] || [ ! -r "$required_public_key" ]; then
              exit 0
            fi

            forwarded_agent_keys="$(${pkgs.openssh}/bin/ssh-add -l 2>/dev/null)" || exit 0
            required_key_record="$(${pkgs.openssh}/bin/ssh-keygen -lf "$required_public_key" 2>/dev/null)" || exit 0
            required_key_fingerprint="''${required_key_record#* }"
            required_key_fingerprint="''${required_key_fingerprint%% *}"
            [ -n "$required_key_fingerprint" ] || exit 0

            case "$forwarded_agent_keys" in
              *" $required_key_fingerprint "*) ;;
              *) exit 0 ;;
            esac

            # Replace the stable link atomically so persistent tmux panes never
            # observe a missing path while concurrent SSH logins reconnect.
            umask 077
            agent_link_tmp="$stable_agent_sock.$$"
            ${pkgs.coreutils}/bin/rm -f "$agent_link_tmp"
            if ${pkgs.coreutils}/bin/ln -s "$SSH_AUTH_SOCK" "$agent_link_tmp"; then
              ${pkgs.coreutils}/bin/mv -f "$agent_link_tmp" "$stable_agent_sock"
            fi
            ${pkgs.coreutils}/bin/rm -f "$agent_link_tmp"
          '';
          executable = mkDefault true;
        };
      }
      // optionalAttrs cfg.envForwarding.enable {
        ".ssh/env-forwarding.conf".source =
          config.hm.lib.file.mkNixConfigSymlink "/configs/ssh/env-forwarding.conf";
      };

      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;

        extraConfig = mkIf cfg.envForwarding.enable (mkAfter ''
          Host ${concatStringsSep " " cfg.envForwarding.hosts}
            Include ${cfg.envForwarding.configFile}
        '');

        settings = {
          "*" = {
            ForwardAgent = true;
            ControlMaster = "auto";
            ControlPersist = "1800";
          };
          "github.com" = {
            HostName = "github.com";
            User = "git";
            IdentityFile = [ "~/.ssh/github-bromanko.pub" ];
            IdentitiesOnly = true;
          };
          github-scherzo-agent = {
            HostName = "github.com";
            User = "git";
            IdentityFile = [ "~/.ssh/github-scherzo-agent.pub" ];
            IdentitiesOnly = true;
          };
          keychain = {
            header = "Host *";
            IgnoreUnknown = "UseKeychain";
            AddKeysToAgent = "yes";
            UseKeychain = "yes";
          };
        };
      };
    };
  };
}
