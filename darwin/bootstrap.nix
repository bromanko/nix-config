{ config, pkgs, lib, ... }:

{
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = "experimental-features = nix-command flakes";

  environment.shells = with pkgs; [ zsh ];
  programs.zsh.enable = true;
  environment.loginShell = pkgs.zsh;
  environment.variables.SHELL = "${pkgs.zsh}/bin/zsh";

  # Completion for system packages
  environment.pathsToLink = [ "/share/zsh" ];

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
