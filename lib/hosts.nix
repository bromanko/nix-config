{
  inputs,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
with inputs;
{
  mkDarwinHost =
    system: path:
    darwin.lib.darwinSystem {
      system = system;
      specialArgs = {
        inherit lib inputs;
      };
      modules = [
        {
          nixpkgs = {
            config = pkgs.${system}.config;
            overlays = pkgs.${system}.overlays;
          };
          networking.hostName = mkDefault (removeSuffix ".nix" (baseNameOf path));
        }
        ../hosts/darwin.nix
        (import path)
      ];
    };

  mkNixosHost =
    path:
    nixosSystem {
      specialArgs = {
        inherit lib inputs;
      };
      system = "x86_64-linux";
      modules = [
        {
          nixpkgs.pkgs = pkgs.x86_64-linux;
          networking.hostName = mkDefault (removeSuffix ".nix" (baseNameOf path));
        }
        ../hosts/nixos.nix
        (import path)
      ];
    };

  mkNixosIso =
    path:
    nixosSystem {
      specialArgs = {
        inherit lib inputs;
      };
      system = "x86_64-linux";
      modules = [
        (
          { modulesPath, ... }:
          {
            imports = [ (modulesPath + "/installer/cd-dvd/installation-cd-minimal.nix") ];
            nixpkgs.pkgs = pkgs.x86_64-linux;
          }
        )
        (import path)
      ];
    };

  mkHmHost =
    system: path:
    home-manager.lib.homeManagerConfiguration {
      pkgs = pkgs.${system};
      extraSpecialArgs = {
        inherit lib inputs;
      };
      modules = [
        ../hosts/home-manager.nix
        {
          home = {
            homeDirectory = "/home/bromanko";
            username = "bromanko";
            stateVersion = "24.11";
          };
        }
        (import path)
      ];
      # nixpkgs = {
      #   config = pkgs.${system}.config;
      #   overlays = pkgs.${system}.overlays;
      # };
    };

  mapDarwinHosts = system: dir: mapModules dir (hostPath: mkDarwinHost system hostPath);

  mapNixosHosts = dir: mapModules dir (hostPath: mkNixosHost hostPath);

  mapNixosIsos = dir: mapModules dir (isoPath: mkNixosIso isoPath);

  mapHomeManagerHosts = system: dir: mapModules dir (hostPath: mkHmHost system hostPath);
}
