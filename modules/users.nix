{ config, options, lib, pkgs, ... }:

with lib;
with lib.my; {
  options = with types; { user = mkOpt attrs { }; };

  config = {
    user = let
      user = builtins.getEnv "USER";
      name = if elem user [ "" "root" ] then "bromanko" else user;
    in {
      inherit name;
      description = "The primary user account";
    };
  };
}
