{ config, lib, pkgs, options, ... }:

with lib;
with lib.my; {
  options = {
    hm = mkOpt' types.attrs { } "Passthrough for home-manager configuration";
  };
  config = {
    # Bootstrap the home-manager config
    # hm = import ../home-manager { inherit config lib pkgs options; };

    home-manager = {
      useGlobalPkgs = true;
      backupFileExtension = "orig";

      # map the hm config to default home-manager user
      users."${config.user.name}" = mkAliasDefinitions options.hm;
    };
  };
}
