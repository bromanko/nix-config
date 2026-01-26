{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;

let
  cfg = config.modules.shell.zsh;
in
{
  config = mkIf cfg.enable {
    programs.zsh = {
      enable = true;
    };

    environment.shells = [ pkgs.zsh ];
  };
}
