{ inputs, lib, pkgs, ... }:

with lib;
with lib.my;
with inputs; {
  mkDarwinHost = system: path:
    darwin.lib.darwinSystem {
      system = system;
      specialArgs = { inherit lib inputs; };
      modules = [
        {
          nixpkgs = {
            config = pkgs.${system}.config;
            overlays = pkgs.${system}.overlays;
          };
          networking.hostName =
            mkDefault (removeSuffix ".nix" (baseNameOf path));
        }
        # This code is same on all architectures
        ../hosts/x86_64-darwin/default.nix
        (import path)
      ];
    };

  mkNixosHost = path:
    nixosSystem {
      specialArgs = { inherit lib inputs; };
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.pkgs = pkgs.x86_64-linux;
          networking.hostName =
            mkDefault (removeSuffix ".nix" (baseNameOf path));
        }
        ../hosts/nixos/default.nix
        (import path)
      ];
    };

  mapDarwinHosts = system: dir:
    mapModules dir (hostPath: mkDarwinHost system hostPath);

  mapNixosHosts = dir: mapModules dir (hostPath: mkNixosHost hostPath);
}
