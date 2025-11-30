{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.homeage;
in
{
  options.modules.homeage = {
    enable = mkBoolOpt false;

    installationType = mkOption {
      type = types.enum [
        "activation"
        "systemd"
      ];
      default = "activation";
      example = "activation";
      description = ''
        Specify the way how secrets should be installed. Either via systemd user services (<literal>systemd</literal>)
        or during the activation of the generation (<literal>activation</literal>).
        </para><para>
        Note: Keep in mind that symlinked secrets will not work after reboots with <literal>activation</literal> if
        <literal>homeage.mount</literal> does not point to persistent location.

        Cleanup notes:
        * Systemd performs cleanup when service stops.
        * Activation performs cleanup after write boundary during activation.
        * When switching from systemd to activation, may need to activate twice.
          Because stopping systemd services, and thus cleanup, happens after
          activation decryption. Only occurs on the first activation.

        Cases when copied file/symlink is not removed:
        1. Symlink does not point to the decrypted secret file.
        2. Any copied file when the original secret file does not exist (can't verify they weren't modified).
        3. Copied file when it does not match the original secret file (using `cmp`).
      '';
    };

    file = mkOption {
      description = "Attrset of secret files";
      default = { };
      type = types.attrs;
    };

    mount = mkOption {
      description = "Absolute path to folder where decrypted files are stored. Files are decrypted on login. Defaults to /run which is a tmpfs.";
      default = "/run/user/$UID/secrets";
      type = types.str;
    };
  };

  config = mkIf cfg.enable {
    hm = {
      imports = [ inputs.homeage.homeManagerModules.homeage ];

      homeage = {
        inherit (cfg) installationType file;

        pkg = pkgs.my.age-with-plugins;

        mount =
          if pkgs.stdenv.hostPlatform.isDarwin then "$HOME/.config/age/secrets" else "/run/user/$UID/secrets";

        identityPaths = [ "$HOME/.config/age/age-identity.txt" ];
      };

      home = {
        packages = with pkgs; [ my.age-with-plugins ];
      };

      xdg.configFile = {
        "age/age-identity.txt".source = ../configs/age/age-identity.txt;
      };
    };
  };
}
