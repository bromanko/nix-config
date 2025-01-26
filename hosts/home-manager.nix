{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
with lib.my;
{
  imports =
    [
      ../modules/users.nix
      ../home-manager
    ]
    # Must toString the path so that nix doesn't attempt to import it to the store
    ++ (mapModulesRec' (toString ../modules/home-manager) import);
}
