{
  pkgs,
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
          fsmonitor = {
            backend = "watchman";
          };
          ui = {
            diff-formatter = [
              "difft"
              "--color=always"
              "$left"
              "$right"
            ];
            paginate = "never";
            default-command = "l";
          };
          templates = {
            log-node = ''
              if(self && !current_working_copy && !immutable && !conflict && in_branch(self),
                "◇",
                builtin_log_node
              )
            '';
          };
          git = {
            subprocess = true;
          };
          remotes = {
            origin = {
              auto-track-bookmarks = "glob:*";
            };
          };
          aliases = {
            n = [ "new" ];
            l = [
              "log"
              "-r"
              "ancestors(reachable(@, mutable()), 2)"
            ];
            tug = [
              "bookmark"
              "move"
              "--from"
              "heads(::@- & bookmarks())"
              "--to"
              "@-"
            ];
            tp = [
              "util"
              "exec"
              "--"
              "bash"
              "-c"
              "jj tug && jj git push"
              ""
            ];
          };
        };
      };
      programs.git = {
        ignores = [ ".jj" ];
      };
      home.packages = with pkgs; [
        jjui
        watchman
      ];
    };
  };
}
