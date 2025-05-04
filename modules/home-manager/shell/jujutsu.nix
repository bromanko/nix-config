{
  config,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.jujutsu;
in
{
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
        settings = {
          user = {
            name = cfg.userName;
            email = cfg.userEmail;
          };
          ui = {
            diff.tool = [
              "difft"
              "--color=always"
              "$left"
              "$right"
            ];
            paginate = "never";
          };
          git = {
            subprocess = true;
          };
          aliases = {
            tug = [
              "bookmark"
              "move"
              "--from"
              "heads(::@- & bookmarks())"
              "--to"
              "@-"
            ];
          };
        };
      };
      programs.git = {
        ignores = [ ".jj" ];
      };
    };
  };
}
