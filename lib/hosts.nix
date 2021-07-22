{ inputs, lib, pkgs, ... }:

with lib;
with lib.my; {
  mkHost = path: {
    modules = [
      {
        networking.hostName = mkDefault (removeSuffix ".nix" (baseNameOf path));
      }
      (import path)
    ];
  };

  mapHosts = dir: mapModules dir (hostPath: mkHost hostPath);
}
