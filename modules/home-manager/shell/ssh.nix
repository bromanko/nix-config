{
  config,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.ssh;
  githubScherzoAgentPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIIv1D8RgQfbHT0lBH6WjBnMSjsNYnH2xbF65cYhU+mQe";
in
{
  options.modules.shell.ssh = with types; {
    enable = mkBoolOpt false;

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
        ".ssh/github-scherzo-agent.pub".text = "${githubScherzoAgentPublicKey}\n";

        # Keep a stable path for forwarded SSH agents. OpenSSH creates a fresh
        # socket for each login, and the concrete path goes stale after sleep,
        # reconnects, or control master churn. This rc hook runs before the
        # user's shell so tmux/fish can safely use ~/.ssh/agent.sock.
        ".ssh/rc" = {
          text = mkDefault ''
            #!/bin/sh
            stable_agent_sock="$HOME/.ssh/agent.sock"

            if [ -n "$SSH_AUTH_SOCK" ] && [ -S "$SSH_AUTH_SOCK" ] && [ "$SSH_AUTH_SOCK" != "$stable_agent_sock" ]; then
              mkdir -p "$HOME/.ssh"
              ln -sfn "$SSH_AUTH_SOCK" "$stable_agent_sock"
            fi
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

        matchBlocks = {
          "*" = {
            forwardAgent = true;
            controlMaster = "auto";
            controlPersist = "1800";
          };
          github-scherzo-agent = {
            hostname = "github.com";
            user = "git";
            identityFile = [ "~/.ssh/github-scherzo-agent.pub" ];
            identitiesOnly = true;
          };
          keychain = {
            host = "*";
            extraOptions = {
              IgnoreUnknown = "UseKeychain";
              AddKeysToAgent = "yes";
              UseKeychain = "yes";
            };
          };
        };
      };
    };
  };
}
