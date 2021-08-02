{ config, options, lib, pkgs, ... }:

with lib; {
  options = with types; { user = mkOpt attrs { }; };

  config = {
    user = let
      user = builtins.getEnv "USER";
      name = if elem user [ "" "root" ] then "bromanko" else user;
    in {
      inherit name;
      description = "The primary user account";
      isNormalUser = true;
      home = "/home/${name}";
      group = "users";
      uid = 1000;
    };
  };
}
