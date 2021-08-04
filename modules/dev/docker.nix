{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev.docker;
in {
  options.modules.dev.docker = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    modules.darwin.homebrew = mkIf (config.systemType == "darwin") {
      taps = [ "homebrew/cask" ];
      casks = [ "docker" ];
    };

    home-manager.users."${config.user.name}" = {
      programs.zsh.shellAliases =
        mkIf config.shell.zsh.enable { dc = "docker-compose"; };
    };
  };
}
