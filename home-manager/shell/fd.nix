{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.fd;
in {
  config = mkIf cfg.enable {
    home.packages = [ pkgs.fd ];

    programs.zsh.shellAliases =
      mkIf config.modules.shell.zsh.enable { find = "${pkgs.fd}/bin/fd"; };
  };
}
