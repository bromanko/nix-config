{
  inputs,
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
{
  imports = [
    (mkAliasOptionModule [ "hm" ] [ "home-manager" "users" config.user.name ])
  ];
  options = {
    nixConfigPath = lib.mkOption {
      type = lib.types.path;
      apply = toString;
      default = "${config.users.users.${config.user.name}.home}/Code/nix-config";
      example = "${config.users.users.${config.user.name}.home}/Code/nix-config";
      description = "Location of the nix-config working copy";
    };
  };
  config = {
    home-manager = {
      useGlobalPkgs = true;
      backupFileExtension = "orig";

      # Workaround to enable installing via `nixos-install`
      # https://github.com/nix-community/home-manager/issues/1262
      sharedModules = [ { manual.manpages.enable = false; } ];
    };

    hm = {
      lib = {
        file = {
          mkNixConfigSymlink =
            path:
            config.hm.lib.file.mkOutOfStoreSymlink (
              config.nixConfigPath + removePrefix (toString inputs.self) (toString path)
            );
        };
      };

      home.activation.verifyActivationHost = lib.hm.dag.entryBefore [ "checkFilesChanged" ] ''
        expectedHost=${escapeShellArg config.networking.hostName}
        actualHost="$(${pkgs.hostname}/bin/hostname -s)"

        if [ "$actualHost" != "$expectedHost" ]; then
          echo "Home Manager activation refused: configuration is for '$expectedHost', but this host is '$actualHost'." >&2
          echo "Activate the matching Darwin or NixOS configuration instead." >&2
          exit 1
        fi
      '';
    };
  };
}
