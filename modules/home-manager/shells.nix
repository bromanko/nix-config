{ config, lib, pkgs, ... }:

{
  environment.shells = with pkgs; [ zsh bash ];
  programs.bash.enable = true;
  programs.zsh.enable = true;
  environment.loginShell = pkgs.zsh;
  environment.variables.SHELL = "${pkgs.zsh}/bin/zsh";

  # Completion for system packages
  environment.pathsToLink = [ "/share/zsh" ];
}
