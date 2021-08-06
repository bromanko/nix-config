{ config, lib, pkgs, inputs, ... }:

with lib;
with lib.my; {
  imports = [
    inputs.home-manager.nixosModules.home-manager
  ]
  # Must toString the path so that nix doesn't attempt to import it to the store
    ++ (mapModulesRec' (toString ../../modules) import);

  nix = {
    package = pkgs.nixFlakes;
    registry.nixpkgs.flake = inputs.nixpkgs;
    extraOptions = ''
      experimental-features = nix-command flakes
      keep-derivations = true
      keep-outputs = true'';
  };

  home-manager = {
    useGlobalPkgs = true;
    backupFileExtension = "orig";

    users."${config.user.name}".home = {

      # This value determines the Home Manager release that your configuration
      # is compatible with. This helps avoid breakage when a new Home Manager
      # release introduces backwards incompatible changes.
      #
      # You can update Home Manager without changing this value. See the Home
      # Manager release notes for a list of state version changes in each
      # release.
      stateVersion = "21.03";
    };
  };

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 4;
}
