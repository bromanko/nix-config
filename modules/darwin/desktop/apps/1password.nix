{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps."1Password";
in
{
  options.modules.desktop.apps."1Password" = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    modules.homebrew = {
      casks = [ "1password" ];
    };

    home-manager.users."${config.user.name}" = {
      home.packages = with pkgs; [
        _1password-cli
        emacsPackages.auth-source-1password
      ];

      programs.ssh = mkIf config.modules.shell.ssh.enable {
        matchBlocks = {
          keychain = lib.mkForce {
            host = "github.com";
            extraOptions = {
              IdentityAgent = ''"~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
            };
          };
        };
      };

      programs.git = mkIf config.modules.shell.git.enable {
        signing = {
          signByDefault = true;
          key = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzLxgUGkWXC/Hkvuxv4rsJfFYrYq1S16DouIXRXD2Ia";
        };
        extraConfig.gpg = {
          format = "ssh";
          ssh.program = "/Applications/1Password.app/Contents/MacOS/op-ssh-sign";
        };
      };
    };
  };
}
