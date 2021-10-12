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
      package = pkgs.nixFlakes;
      registry.nixpkgs.flake = inputs.nixpkgs;
      extraOptions = ''
        extra-platforms = x86_64-darwin aarch64-darwin
        experimental-features = nix-command flakes
        keep-derivations = true
        keep-outputs = true'';
    };

    users.users.${config.user.name} = mkAliasDefinitions config.user;

    hm = {
      home = {
        activation = {
          copyApplications = let
            apps = pkgs.buildEnv {
              name = "home-manager-applications";
              paths =
                config.home-manager.users."${config.user.name}".home.packages;
              pathsToLink = "/Applications";
            };
          in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            # Install MacOS applications to the user environment.
            HM_APPS="$HOME/Applications/Home Manager Apps"

            # Reset current state
            [ -e "$HM_APPS" ] && $DRY_RUN_CMD rm -r "$HM_APPS"
            $DRY_RUN_CMD mkdir -p "$HM_APPS"

            # .app dirs need to be actual directories for Finder to detect them as Apps.
            # The files inside them can be symlinks though.
            # Modes need to be stripped because otherwise the dirs wouldn't have +w,
            # preventing us from deleting them again
            # In the env of Apps we build, the .apps are symlinks. We pass all of them as
            # arguments to cp and make it dereference those using -H
            echo "Linking Home Manager Apps to $HM_APPS..."
            $DRY_RUN_CMD cp --recursive --symbolic-link --no-preserve=mode -H ${apps}/Applications/* "$HM_APPS"
          '';
        };

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
