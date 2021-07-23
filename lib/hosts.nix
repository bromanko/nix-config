{ inputs, lib, pkgs, ... }:

with lib;
with lib.my;
with inputs; {
  mkDarwinHost = path:
    darwin.lib.darwinSystem {
      modules = [
        {
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
          networking.hostName =
            mkDefault (removeSuffix ".nix" (baseNameOf path));
        }
        (import path)
      ];
    };

  mapHosts = mkHost: dir: mapModules dir (hostPath: mkHost hostPath);

  mapDarwinHosts = dir: (mapHosts mkDarwinHost dir);

  mapNixosHosts = dir: (mapHosts mkNixosHost dir);
}
