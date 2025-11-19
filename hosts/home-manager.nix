{
  lib,
  config,
  inputs,
  ...
}:

with lib;
with lib.my;
let
  # Forward hm.* modules to the top-level namespace in standalone mode.
  mkHmForwardOption =
    name:
    { options, ... }:
    {
      options.hm.${name} = mkOption {
        type = types.attrs;
        default = { };
      };
      config.${name} = mkAliasDefinitions options.hm.${name};
    };

  hmForwardModules = map mkHmForwardOption [
    "home"
    "programs"
    "services"
    "xdg"
    "homeage"
  ];
in
{
  imports = [
    # Import homeage directly since hm.imports doesn't work in standalone mode
    inputs.homeage.homeManagerModules.homeage
    ../modules/homeage.nix
    ../modules/home-manager-nix.nix
  ]
  ++ hmForwardModules
  ++ [
    {
      options.hm = {
        lib = mkOption {
          type = types.attrs;
          default = { };
          description = "Library functions for hm modules";
        };
        imports = mkOption {
          type = types.listOf types.anything;
          default = [ ];
          internal = true;
          description = "Ignored in standalone home-manager mode";
        };
      };
    }
  ]
  # Must toString the path so that nix doesn't attempt to import it to the store
  ++ (mapModulesRec' (toString ../modules/home-manager) import);

  config = {
    hm.lib.file.mkNixConfigSymlink =
      path:
      config.lib.file.mkOutOfStoreSymlink (
        "${config.home.homeDirectory}/Code/nix-config" + removePrefix (toString inputs.self) (toString path)
      );

    # Enable Nix daemon integration for standalone home-manager on non-NixOS Linux
    targets.genericLinux.enable = true;

    # Disable manual generation - causes Python multiprocessing issues in sandbox
    manual.manpages.enable = false;
  };
}
