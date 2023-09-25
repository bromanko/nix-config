{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.exa;
in {
  config = mkIf cfg.enable {
    home.packages = [ pkgs.eza ];

    programs.zsh.shellAliases = mkIf config.modules.shell.zsh.enable {
      ls = "${pkgs.eza}/bin/eza";
      ll = "ls -l --time-style long-iso --icons";
      l = "ll -a";
    };
  };
}
