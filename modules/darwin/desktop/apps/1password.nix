{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.apps."1Password";
in {
  options.modules.desktop.apps."1Password" = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    modules.homebrew = {
      taps = [ "homebrew/cask" ];
      casks = [ "1password" ];
    };

    home-manager.users."${config.user.name}" = {
      home.packages = with pkgs; [
        _1password
        emacsPackages.auth-source-1password
      ];

      programs.ssh = {
        matchBlocks = {
          keychain = {
            host = "*";
            extraOptions = {
              IdentityAgent = ''
                "~/Library/Group Containers/2BUA8C4S2C.com.1password/t/agent.sock"'';
            };
          };
        };
      };
    };
  };
}
