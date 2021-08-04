{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.exa;
in {
  options.modules.shell.exa = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}" = {
      home.packages = [ pkgs.exa ];

      programs.zsh.shellAliases = mkIf config.shell.zsh.enable {
        ls = "${pkgs.exa}/bin/exa";
        ll = "ls -l --time-style long-iso --icons";
        l = "ll -a";
      };

    };
  };
}
