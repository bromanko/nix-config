{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev.docker;
in {
  options.modules.dev.docker = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    modules.homebrew = { casks = [ "docker" ]; };

    home-manager.users."${config.user.name}" = {
      programs.zsh.shellAliases =
        mkIf config.modules.shell.zsh.enable { dc = "docker-compose"; };
    };
  };
}
