{ inputs, lib, pkgs, ... }:

with lib;
with lib.my;
with inputs; {
  mkDarwinHost = path:
    darwin.lib.darwinSystem {
      specialArgs = { inherit lib inputs; };
      modules = [
        {
          nixpkgs = {
            config = pkgs.config;
            overlays = pkgs.overlays;
          };
          networking.hostName =
            mkDefault (removeSuffix ".nix" (baseNameOf path));
        }
        ../hosts/darwin/default.nix
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
        ../hosts/nixos/default.nix
        (import path)
      ];
    };

  mapDarwinHosts = dir: mapModules dir (hostPath: mkDarwinHost hostPath);

  mapNixosHosts = dir: mapModules dir (hostPath: mkNixosHost dir);
}
