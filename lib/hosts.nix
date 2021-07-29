{ inputs, lib, pkgs, ... }:

with lib;
with lib.my;
with inputs; {
  mkDarwinHost = path:
    darwin.lib.darwinSystem {
      modules = [
        {
          nixpkgs = {
            config = pkgs.config;
            overlays = pkgs.overlays;
          };
        }
        {
          networking.hostName =
            mkDefault (removeSuffix ".nix" (baseNameOf path));
        }
        ../modules/darwin
        (import path)
        # home-manager.darwinModule
        # {

        # }
      ];
    };

  mkNixosHost = path:
    nixosSystem {
      specialArgs = { inherit lib inputs; };
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.pkgs = pkgs;
          networking.hostName =
            mkDefault (removeSuffix ".nix" (baseNameOf path));
        }
        (import path)
      ];
    };

  # mapHosts = mkHost: dir: mapModules dir (hostPath: mkHost hostPath);

  mapDarwinHosts = dir: mapModules dir (hostPath: mkDarwinHost hostPath);

  # mapNixosHosts = dir: (mapHosts (mkNixosHost dir));
}
