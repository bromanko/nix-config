{ config, lib, pkgs, ... }:

with lib;
with lib.my;

let cfg = config.modules.shell.fish;
in {
  config = mkIf cfg.enable {
    programs.fish = { enable = true; };

    environment = {
      shells = [ pkgs.fish ];
      pathsToLink = [ "/share/zsh" ];
    };
  };
}
