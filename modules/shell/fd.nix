{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.fd;
in {
  options.modules.shell.fd = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}" = {
      home.packages = [ pkgs.fd ];

      programs.zsh.shellAliases =
        mkIf config.shell.zsh.enable { find = "${pkgs.fd}/bin/fd"; };
    };
  };
}
