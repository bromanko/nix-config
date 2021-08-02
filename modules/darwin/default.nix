{ config, options, lib, ststs, ... }:

with lib;
with lib.my; {
  options = with types; { user = mkOpt attrs { }; };

  config = mkIf (config.systemType == "darwin") {
    user = let
      user = builtins.getEnv "USER";
      name = if elem user [ "" "root" ] then "bromanko" else user;
    in {
      inherit name;
      description = "The primary user account";
      home = "/home/${name}";
    };

    users.users.${config.user.name} = mkAliasDefinitions options.user;
  };
}
