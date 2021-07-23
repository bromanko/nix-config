{ inputs, lib, pkgs, ... }:

with lib;
with lib.my;
with inputs; {
  mkDarwinHost = overlays: path:
    darwin.lib.darwinSystem {
      modules = [
        {
          nix.package = pkgs.nixFlakes;
          nixpkgs = {
            config.allowUnfree = true;
            overlays = overlays;
          };

          nix.extraOptions = ''
            experimental-features = nix-command flakes
            keep-derivations = true
            keep-outputs = true
          '';

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 4;
        }
        {
          networking.hostName =
            mkDefault (removeSuffix ".nix" (baseNameOf path));
        }
        # ../modules/home-manager.nix
        # ../darwin
        (import path)
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

  mapHosts = mkHost: dir: mapModules dir (hostPath: mkHost hostPath);

  mapDarwinHosts = dir: overlays: mapHosts (mkDarwinHost overlays) dir;

  mapNixosHosts = dir: (mapHosts (mkNixosHost dir));
}
