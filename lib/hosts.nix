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
        ../hosts/darwin.nix
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
        ../hosts/nixos.nix
        (import path)
      ];
    };

  mkHmHost = system: path:
    # convert all of the home-manager config to be bare (no users.foo)
    # Then, import it directly here
    # Then, change the way that the home-manager config is set in nix and darwin
    # so that it is using an alias definition?
    # home-manager.users.foo = mkAliasDefinitions options.hm
    home-manager.lib.homeManagerConfiguration {
      inherit system;
      pkgs = pkgs.${system};
      extraSpecialArgs = { inherit lib inputs; };
      homeDirectory = "/home/bromanko";
      username = "bromanko";
      configuration = {
        imports = [ ../hosts/home-manager.nix (import path) ];
        nixpkgs = {
          config = pkgs.${system}.config;
          overlays = pkgs.${system}.overlays;
        };
      };
    };

  mapDarwinHosts = system: dir:
    mapModules dir (hostPath: mkDarwinHost system hostPath);

  mapNixosHosts = dir: mapModules dir (hostPath: mkNixosHost hostPath);

  mapHomeManagerHosts = system: dir:
    mapModules dir (hostPath: mkHmHost system hostPath);
}
