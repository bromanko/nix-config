{ config, options, lib, pkgs, ... }:

with lib;
with lib.my; {
  options = with types; { user = mkOpt attrs { }; };

  config = mkIf (config.systemType == "darwin") {
    user = let
      user = builtins.getEnv "USER";
      name = if elem user [ "" "root" ] then "bromanko" else user;
    in {
      inherit name;
      description = "The primary user account";
      home = "/home/${name}";
    };

    users.users.${config.user.name} = mkAliasDefinitions options.user;

    home-manager = {
      useGlobalPkgs = true;
      users."${config.user.name}".home.activation = {
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
          $DRY_RUN_CMD cp --recursive --symbolic-link --no-preserve=mode -H ${apps}/Applications/* "$HM_APPS"
          # Modes need to be stripped because otherwise the dirs wouldn't have +w,
          # preventing us from deleting them again
          # In the env of Apps we build, the .apps are symlinks. We pass all of them as
          # arguments to cp and make it dereference those using -H
        '';
      };
    };
  };
}
