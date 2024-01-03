{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.dictionaries;
in {
  options.modules.desktop.dictionaries = with types; {
    enable = mkBoolOpt false;

    dictionaries = mkOption {
      type = types.listOf types.path;
      default = [ pkgs.my.websters-1913 ];
      example = literalExpression "[ pkgs.my.websters-1913 ]";
      description = "List of dictionaries to install.";
    };
  };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}".home.activation.installDictionaries =
      ''
        # Set up dictionaries.
        echo "configuring dictionaries..." >&2
        mkdir -p $HOME/Library/Dictionaries

        declare -a dictionaries=( ${toString (lib.toList cfg.dictionaries)} )
        for path in $dictionaries; do
          find -L $path -type d -name "*.dictionary" -print0 | while IFS= read -rd "" f; do
            # Must copy the dictionary since symlinks don't work with Dictionary.app
            cp -rf "$f" $HOME/Library/Dictionaries
          done
        done
        chmod -R 755 $HOME/Library/Dictionaries/
      '';
  };
}
