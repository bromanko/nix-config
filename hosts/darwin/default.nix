{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.my; {
  imports = [
    inputs.home-manager.darwinModules.home-manager
  ]
  # Must toSting the path so that nix doesn't attempt to import it to the store
    ++ (mapModulesRec' (toString ../../modules) import);

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

  home-manager.users."${config.user.name}".home = {
    packages = with pkgs; [ m-cli ];
  };

  systemType = "darwin";
  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
