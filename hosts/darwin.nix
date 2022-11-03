{ config, lib, pkgs, inputs, options, ... }:

with lib;
with lib.my; {
  imports = [
    inputs.home-manager.darwinModules.home-manager
    ../modules/users.nix
    ../modules/fonts.nix
    ../modules/home-manager.nix
  ]
  # Must toString the path so that nix doesn't attempt to import it to the store
    ++ (mapModulesRec' (toString ../modules/home-manager) import)
    ++ (mapModulesRec' (toString ../modules/darwin) import);

  config = {
    nix = {
      package = pkgs.nix;
      extraOptions = ''
        extra-platforms = x86_64-darwin aarch64-darwin
        experimental-features = nix-command flakes
        keep-derivations = true
        keep-outputs = true'';
    };

    users.users.${config.user.name} = mkAliasDefinitions config.user;

    hm = {
      home = {
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
  };
}
