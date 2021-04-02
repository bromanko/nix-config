{ config, pkgs, lib, ... }:

{
  nix.trustedUsers = [ "@admin" ];
  users.nix.configureBuildUsers = true;

  nix.package = pkgs.nixFlakes;
  nix.extraOptions = "experimental-features = nix-command flakes";

  # Auto upgrade nix package and the daemon service.
  services.nix-daemon.enable = true;

  environment.shells = with pkgs; [ zsh ];

  programs.zsh.enable = true;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
