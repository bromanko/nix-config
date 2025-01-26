{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.fd;
in
{
  options.modules.shell.fd = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home.packages = [ pkgs.fd ];

      programs.zsh.shellAliases = mkIf config.modules.shell.zsh.enable { find = "${pkgs.fd}/bin/fd"; };
    };
  };
}
