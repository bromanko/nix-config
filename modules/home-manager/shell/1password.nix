{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell."1password";
in
{
  options.modules.shell."1password" = {
    enable = mkBoolOpt false;

    sshSocketPath = mkOption {
      type = types.str;
      default =
        if pkgs.stdenv.isDarwin then
          "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        else
          "~/.1password/agent.sock";
      description = "Path to the 1Password SSH agent socket";
    };

    sshSigningProgramPath = mkOption {
      type = types.nullOr types.str;
      default =
        if pkgs.stdenv.isDarwin then "/Applications/1Password.app/Contents/MacOS/op-ssh-sign" else null;
      description = "Path to op-ssh-sign for git commit signing. Set to null to disable signing.";
    };

    gitSigningKey = mkOption {
      type = types.nullOr types.str;
      default = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzLxgUGkWXC/Hkvuxv4rsJfFYrYq1S16DouIXRXD2Ia";
      description = "SSH public key to use for git commit signing";
    };
  };

  config = mkIf cfg.enable {
    hm = {
      home.packages =
        with pkgs;
        [ _1password-cli ]
        ++ optionals config.modules.editor.emacs.enable [ emacsPackages.auth-source-1password ];

      home.sessionVariables = {
        OP_BIOMETRIC_UNLOCK_ENABLED = "true";
        # Use 1Password SSH agent for all SSH operations (including agent forwarding)
        # Replace ~ with $HOME since environment variables don't expand tildes
        SSH_AUTH_SOCK =
          if lib.hasPrefix "~/" cfg.sshSocketPath
          then "\${HOME}" + lib.removePrefix "~" cfg.sshSocketPath
          else cfg.sshSocketPath;
      };

      programs.ssh = mkIf config.modules.shell.ssh.enable {
        matchBlocks = {
          "1password" = {
            host = "*";
            extraOptions = {
              IdentityAgent = ''"${cfg.sshSocketPath}"'';
            };
          };
        };
      };

      programs.git =
        mkIf
          (config.modules.shell.git.enable && cfg.sshSigningProgramPath != null && cfg.gitSigningKey != null)
          {
            signing = {
              signByDefault = true;
              key = cfg.gitSigningKey;
            };
            extraConfig.gpg = {
              format = "ssh";
              ssh.program = cfg.sshSigningProgramPath;
            };
          };
    };
  };
}
