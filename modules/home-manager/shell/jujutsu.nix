{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.shell.jujutsu;
  jj1Password = pkgs.jujutsu.overrideAttrs (old: {
    nativeBuildInputs = old.nativeBuildInputs ++ [ pkgs.makeWrapper ];
    postInstall = ''
      # Export via run rather than set to expand the ~ variable
      wrapProgram $out/bin/jj \
        --run "export SSH_AUTH_SOCK=~/Library/Group\ Containers/2BUA8C4S2C.com.1password/t/agent.sock"
    '';
  });
in {
  options.modules.shell.jujutsu = {
    enable = mkBoolOpt false;

    userEmail = mkOption {
      type = types.str;
      default = "hello@bromanko.com";
    };

    userName = mkOption {
      type = types.str;
      default = "Brian Romanko";
    };
  };

  config = mkIf cfg.enable {
    hm = {
      programs.jujutsu = {
        enable = true;
        package =
          mkIf config.modules.desktop.apps."1Password".enable jj1Password;
        settings = {
          user = {
            name = cfg.userName;
            email = cfg.userEmail;
          };
          ui.diff.tool = [ "difft" "--color=always" "$left" "$right" ];
        };
      };

      # On Darwin jj reads from $HOME/Library/Application Support/jj/config.toml
      # See https://github.com/martinvonz/jj/issues/3434
      home = mkIf pkgs.stdenv.isDarwin {
        activation = {
          jjConfig = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
            mkdir -p "$HOME/Library/Application Support/jj"
            rm -f "$HOME/Library/Application Support/jj/config.toml"
            ln -s $HOME/.config/jj/config.toml "$HOME/Library/Application Support/jj/config.toml"
          '';
        };
      };

      programs.git = { ignores = [ ".jj" ]; };
    };
  };
}
