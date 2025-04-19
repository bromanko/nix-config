{ lib, ... }:

with lib;
with lib.my;
{
  options = with types; {
    user = mkOpt attrs { };
    authorizedKeys = mkOption {
      type = types.listOf types.str;
      default = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2vkvKlul2zm/Qx7V0NmmwGDJcFY46tf9asOVONkcCK Meta MacBook Pro 16"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzLxgUGkWXC/Hkvuxv4rsJfFYrYq1S16DouIXRXD2Ia Personal MacBook Air"
      ];
      description = ''
        A list of verbatim OpenSSH public keys that should be added to the
        user's authorized keys. The keys are added to a file that the SSH
        daemon reads in addition to the the user's authorized_keys file.
      '';
    };
  };

  config = {
    user =
      let
        user = builtins.getEnv "USER";
        name =
          if
            elem user [
              ""
              "root"
            ]
          then
            "bromanko"
          else
            user;
      in
      {
        inherit name;
        description = "The primary user account";
      };
  };
}
