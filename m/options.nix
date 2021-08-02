{ config, options, lib, ststs, ... }:

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

    users.users.${config.user.name} = mkAliasDefinitions options.user;
  };

}
