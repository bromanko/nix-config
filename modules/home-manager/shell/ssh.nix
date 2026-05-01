{
  config,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.ssh;
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
