{
  config,
  lib,
  options,
  ...
}:

with lib;
with lib.my;
{
  imports = [
    (mkAliasOptionModule [ "hm" ] [ "home-manager" "users" config.user.name ])
  ];
  options = {
  };
  config = {
    home-manager = {
      useGlobalPkgs = true;
      backupFileExtension = "orig";

      # Workaround to enable installing via `nixos-install`
      # https://github.com/nix-community/home-manager/issues/1262
      sharedModules = [ { manual.manpages.enable = false; } ];

    };
  };
}
