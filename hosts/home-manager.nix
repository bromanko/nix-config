{
  lib,
  ...
}:

with lib;
with lib.my;
{
  imports =
    [
      ../modules/users.nix
    ]
    # Must toString the path so that nix doesn't attempt to import it to the store
    ++ (mapModulesRec' (toString ../modules/home-manager) import);
}
