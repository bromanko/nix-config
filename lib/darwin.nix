{ inputs, lib, pkgs, ... }:

with lib;
with lib.my; {
  mkHost = path:
    attrs@{ ... }:
    darwin.lib.darwinSystem {
      specialArgs = { inherit lib inputs; };
      modules = [
        {
          nixpkgs.pkgs = pkgs;
          networking.hostName =
            mkDefault (removeSuffix ".nix" (baseNameOf path));
        }
        ../. # /default.nix
        (import path)
      ];
    };

  mapDarwinHosts = dir: attrs: mapModules dir (hostPath: mkHost hostPath attrs);
}
