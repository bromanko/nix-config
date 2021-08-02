{ inputs, lib, pkgs, ... }:

with lib.my;
with inputs; {
  mkDarwinHost = path:
    darwin.lib.darwinSystem {
      specialArgs = { inherit lib inputs; };
      modules = [
        (import ../hosts/darwin/default.nix)
        {
          nixpkgs = {
            config = pkgs.config;
            overlays = pkgs.overlays;
          };

          networking.hostName =
            mkDefault (removeSuffix ".nix" (baseNameOf path));
        }
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

  # mapHosts = mkHost: dir: mapModules dir (hostPath: mkHost hostPath);

  mapDarwinHosts = dir: mapModules dir (hostPath: mkDarwinHost hostPath);

  # mapNixosHosts = dir: (mapHosts (mkNixosHost dir));
}
