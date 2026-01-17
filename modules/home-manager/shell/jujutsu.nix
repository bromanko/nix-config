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
    # Enable delta for beautiful diffs
    modules.shell.delta.enable = true;

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
            # Use delta for beautiful side-by-side diffs with syntax highlighting
            # Mimics vim-fugitive's :Gdiff with background highlights and preserved syntax
            # Reference the delta tool defined in merge-tools
            diff-formatter = "delta";
            diff-editor = ":builtin";
            # Use 'auto' pagination so delta can detect terminal width properly
            # This allows delta to use full terminal width in side-by-side mode
            paginate = "auto";
            pager = "less -FRX";
            default-command = "l";
          };
          # Custom delta feature for jj that emphasizes changes while preserving syntax
          merge-tools.delta = {
            program = "delta";
            diff-args = [
              "--true-color"
              "always"
              "--side-by-side"
              "--line-numbers"
              "--width=$width"
              "--syntax-theme"
              "Catppuccin Mocha"
              "--features"
              "catppuccin-custom"
              "$left"
              "$right"
            ];
            # Delta exits with status 1 when there are differences (standard diff behavior)
            # This tells jj that both 0 (no differences) and 1 (differences found) are expected
            diff-expected-exit-codes = [
              0
              1
            ];
          };
          # Non-split delta for jjui preview (avoids width detection issues)
          merge-tools.delta-non-split = {
            program = "delta";
            diff-args = [
              "--width=$width"
              "--features"
              "catppuccin-non-split"
              "$left"
              "$right"
            ];
            diff-expected-exit-codes = [
              0
              1
            ];
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

      # jjui theme configuration
      xdg.configFile."jjui/themes/base24-catppuccin-mocha.toml".text = ''
        ## tinted-jjui (https://github.com/vic/tinted-jjui)
        # Scheme name: Catppuccin Mocha
        # Scheme author: https://github.com/catppuccin/catppuccin
        # Template author: Victor Borja <vborja@apache.org> (https://github.com/vic)

        "text"      = { fg = "#cdd6f4", bg = "#1e1e2e" }
        "dimmed"    = { fg = "#45475a", bg = "#1e1e2e" }
        "title"     = { fg = "#89b4fa", bold = true }
        "shortcut"  = { fg = "#cba6f7" }
        "matched"   = { fg = "#f5e0dc" }
        "border"    = { fg = "#45475a" }
        "selected"  = { bg = "#181825", fg = "#cdd6f4", bold = true }

        "source_marker" = { bg = "#181825", fg = "#1e1e2e", bold = true }
        "target_marker" = { bg = "#11111b", fg = "#1e1e2e", bold = true }

        "status" = { bg = "#181825" }
        "status title" = { fg = "#1e1e2e", bg = "#74c7ec", bold = true }

        "revset title" = { fg = "#89b4fa", bold = true }
        "revset text" = { fg = "#cdd6f4", bold = true }
        "revset completion text" = { fg = "#cdd6f4" }
        "revset completion matched" = { fg = "#f5e0dc", bold = true }
        "revset completion dimmed" = { fg = "#45475a" }
        "revset completion selected" = { bg = "#313244", fg = "#cdd6f4" }

        "revisions" = { fg = "#cdd6f4" }
        "revisions selected" = { bg = "#181825"}
        "revisions dimmed" = { fg = "#45475a" }
        "revisions details selected" = { bg = "#313244" }
        "oplog selected" = { bold = true }

        "evolog" = { fg = "#cdd6f4" }
        "evolog selected" = { bg = "#313244", fg = "#cdd6f4", bold = true }

        "menu" = { bg = "#1e1e2e" }
        "menu title" = { fg = "#1e1e2e", bg = "#f5c2e7", bold = true }
        "menu shortcut" = { fg = "#f5c2e7" }
        "menu matched" = { fg = "#f5e0dc", bold = true }
        "menu dimmed" = { fg = "#45475a" }
        "menu border" = { fg = "#181825" }
        "menu selected" = { bg = "#313244", fg = "#cdd6f4" }

        "help" = { bg = "#1e1e2e" }
        "help title" = { fg = "#a6e3a1", bold = true, underline = true }
        "help border" = { fg = "#181825" }

        "preview" = { fg = "#cdd6f4" }
        "preview border" = { fg = "#181825" }

        "confirmation" = { bg = "#1e1e2e" }
        "confirmation text" = { fg = "#89b4fa", bold = true }
        "confirmation dimmed" = { fg = "#45475a" }
        "confirmation border" = { fg = "#eba0ac", bold = true }
        "confirmation selected" = { bg = "#313244", fg = "#cdd6f4" }

        "undo" = { bg = "#1e1e2e" }
        "undo confirmation dimmed" = { fg = "#45475a" }
        "undo confirmation selected" = { bg = "#313244", fg = "#cdd6f4" }

        "success" = { fg = "#a6e3a1", bold = true }
        "error" = { fg = "#eba0ac", bold = true }
        "revisions rebase source_marker" = { bold = true }
        "revisions rebase target_marker" = { bold = true }
        "status shortcut" = { fg = "#f5c2e7" }
        "status dimmed" = { fg = "#45475a" }

        "details" = { fg = "#cdd6f4" }
        "details selected" = { bold = true }
        "completion" = { fg = "#cdd6f4" }
        "completion selected" = { bold = true }
        "rebase" = { bold = true }

        "workspace" = { fg = "#74c7ec" }
        "branch" = { fg = "#89dceb" }
        "commit" = { fg = "#a6e3a1" }
        "file" = { fg = "#f5e0dc" }
        "change" = { fg = "#eba0ac" }
        "bookmark" = { fg = "#f5c2e7" }
      '';

      xdg.configFile."jjui/config.toml".text = ''
        theme = "base24-catppuccin-mocha"

        # Use non-split delta in preview to avoid width detection issues
        # Side-by-side still works in full terminal via jj diff
        [preview]
        revision_command = ["show", "--color", "always", "-r", "$change_id", "--config", "ui.diff-formatter=delta-non-split"]
        file_command = ["diff", "--color", "always", "-r", "$change_id", "--config", "ui.diff-formatter=delta-non-split", "$file"]
      '';
    };
  };
}
