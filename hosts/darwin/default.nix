{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.my; {
  imports = [ inputs.home-manager.darwinModules.home-manager ]
    ++ (mapModulesRec' ../../modules import);

  nix = {
    package = pkgs.nixFlakes;
    registry.nixpkgs.flake = inputs.nixpkgs;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-derivations = true
      keep-outputs = true'';
  };

  fonts.enableFontDir = true;
  fonts.fonts = with pkgs; [ my.fantasque-sans-mono-nerd-font ];

  systemType = "darwin";
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
