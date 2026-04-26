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
  homeDir =
    if config ? home && config.home ? homeDirectory then
      config.home.homeDirectory
    else if config ? hm && config.hm ? home && config.hm.home ? homeDirectory then
      config.hm.home.homeDirectory
    else
      config.users.users.${config.user.name}.home;
  sshSocketPath =
    if lib.hasPrefix "~/" cfg.sshSocketPath then
      homeDir + lib.removePrefix "~" cfg.sshSocketPath
    else
      cfg.sshSocketPath;
in
{
  options.modules.shell."1password" = {
    enable = mkBoolOpt false;

    sshSocketPath = mkOption {
      type = types.str;
      default =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"
        else
          "~/.1password/agent.sock";
      description = "Path to the 1Password SSH agent socket";
    };

    sshSigningProgramPath = mkOption {
      type = types.nullOr types.str;
      default =
        if pkgs.stdenv.hostPlatform.isDarwin then
          "/Applications/1Password.app/Contents/MacOS/op-ssh-sign"
        else
          null;
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
      };

      # Preserve forwarded SSH agents when logging into a macOS host over SSH/ET.
      # ET's `--forward-ssh-agent` sets SSH_AUTH_SOCK to an `et_forward_sock_*`
      # reverse-tunnel socket, but it does not set SSH_CONNECTION. Do not use
      # SSH_CONNECTION as the proxy for "remote session" detection; instead,
      # replace only missing/broken sockets and macOS' stock launchd agent.
      programs.zsh.initExtra =
        mkIf (config.modules.shell.zsh.enable && pkgs.stdenv.hostPlatform.isDarwin)
          ''
            if [[ -S "${sshSocketPath}" ]]; then
              ssh_auth_sock_needs_1password=0

              if [[ -z "$SSH_AUTH_SOCK" || ! -S "$SSH_AUTH_SOCK" ]]; then
                ssh_auth_sock_needs_1password=1
              else
                case "$SSH_AUTH_SOCK" in
                  /private/tmp/com.apple.launchd.*/Listeners|/tmp/com.apple.launchd.*/Listeners|/var/folders/*/T/com.apple.launchd.*/Listeners)
                    ssh_auth_sock_needs_1password=1
                    ;;
                esac
              fi

              if [[ "$ssh_auth_sock_needs_1password" == 1 ]]; then
                export SSH_AUTH_SOCK="${sshSocketPath}"
              fi

              unset ssh_auth_sock_needs_1password
            fi
          '';

      programs.fish.interactiveShellInit =
        mkIf (config.modules.shell.fish.enable && pkgs.stdenv.hostPlatform.isDarwin)
          ''
            if test -S "${sshSocketPath}"
              set -l ssh_auth_sock_needs_1password 0

              if test -z "$SSH_AUTH_SOCK"; or not test -S "$SSH_AUTH_SOCK"
                set ssh_auth_sock_needs_1password 1
              else if string match -q -- "/private/tmp/com.apple.launchd.*/Listeners" "$SSH_AUTH_SOCK"
                set ssh_auth_sock_needs_1password 1
              else if string match -q -- "/tmp/com.apple.launchd.*/Listeners" "$SSH_AUTH_SOCK"
                set ssh_auth_sock_needs_1password 1
              else if string match -q -- "/var/folders/*/T/com.apple.launchd.*/Listeners" "$SSH_AUTH_SOCK"
                set ssh_auth_sock_needs_1password 1
              end

              if test "$ssh_auth_sock_needs_1password" = 1
                set -gx SSH_AUTH_SOCK "${sshSocketPath}"
              end
            end
          '';

      programs.git =
        mkIf
          (config.modules.shell.git.enable && cfg.sshSigningProgramPath != null && cfg.gitSigningKey != null)
          {
            signing = {
              format = "ssh";
              signByDefault = true;
              key = cfg.gitSigningKey;
            };
            settings.gpg.ssh.program = cfg.sshSigningProgramPath;
          };
    };
  };
}
