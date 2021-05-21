{ config, pkgs, lib, ... }:

{
  nix.package = pkgs.nixFlakes;
  nix.extraOptions = ''
    experimental-features = nix-command flakes
    keep-derivations = true
    keep-outputs = true
  '';

  environment.shells = with pkgs; [ zsh bash ];
  programs.bash.enable = true;
  programs.zsh.enable = true;
  environment.loginShell = pkgs.zsh;
  environment.variables.SHELL = "${pkgs.zsh}/bin/zsh";

  # Completion for system packages
  environment.pathsToLink = [ "/share/zsh" ];

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
