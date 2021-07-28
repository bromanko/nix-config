{ inputs, lib, pkgs, ... }:

let user = builtins.getEnv "USER";
in with lib;
with lib.my;
with inputs; {
  mkDarwinHost = overlays: path:
    darwin.lib.darwinSystem {
      modules = [
        {
          nix.package = pkgs.nixFlakes;
          nix.extraOptions = ''
            experimental-features = nix-command flakes
            keep-derivations = true
            keep-outputs = true
          '';

          nixpkgs = {
            config.allowUnfree = true;
            overlays = overlays;
          };

          # Used for backwards compatibility, please read the changelog before changing.
          # $ darwin-rebuild changelog
          system.stateVersion = 4;
        }
        { users.users.${user}.home = builtins.getEnv "HOME"; }
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
