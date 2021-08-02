{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let
  isDarwin = config.systemType == "darwin";
  isNotDarwin = !isDarwin;

  cfg = config.modules.shell.zsh;

  darwinCfg = {
    programs.zsh.enable = true;

    environment.shells = [ pkgs.zsh ];
    environment.loginShell = pkgs.zsh;
    environment.variables.SHELL = "${pkgs.zsh}/bin/zsh";

    # Completion for system packages
    environment.pathsToLink = [ "/share/zsh" ];
  };

  nixosCfg = { };
in {
  options.modules.shell.zsh = with types; { enable = mkBoolOpt false; };

  config = mkIf cfg.enable
    (mkMerge [ (mkIf isDarwin darwinCfg) (mkIf isNotDarwin nixosCfg) ]);
}
