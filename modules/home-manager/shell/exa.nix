{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.exa;
  shellAliases = {
    ls = "${pkgs.eza}/bin/eza";
    ll = "ls -l --time-style long-iso --icons";
    l = "ll -a";
  };
in
{
  options.modules.shell.exa = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home.packages = [ pkgs.eza ];

      programs.zsh.shellAliases = mkIf config.modules.shell.zsh.enable shellAliases;
      programs.fish.shellAliases = mkIf config.modules.shell.fish.enable shellAliases;
    };
  };
}
