{
  config,
  lib,
  options,
  ...
}:

with lib;
with lib.my;
{
  options = {
    hm = mkOpt' types.attrs { } "Passthrough for home-manager configuration";
  };
  config = {
    home-manager = {
      useGlobalPkgs = true;
      backupFileExtension = "orig";

      # Workaround to enable installing via `nixos-install`
      # https://github.com/nix-community/home-manager/issues/1262
      sharedModules = [ { manual.manpages.enable = false; } ];

      # map the hm config to default home-manager user
      users."${config.user.name}" = mkAliasDefinitions options.hm;
    };
  };
}
