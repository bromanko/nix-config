{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.delta;
in
{
  options.modules.shell.delta = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      programs.delta = {
        enable = true;
        # Enable git integration to automatically use delta for git diff/log
        enableGitIntegration = true;
        options = {
          # Custom feature that mimics vim-fugitive's :Gdiff style:
          # - Side-by-side layout
          # - Syntax highlighting preserved
          # - Background highlights for changes (like the Solarized patch)
          # - +/- indicators in the gutter
          features = "catppuccin-custom";

          catppuccin-custom = {
            # Core display settings
            side-by-side = true;
            line-numbers = true;
            syntax-theme = "Catppuccin Mocha";
            true-color = "always";

            # Keep +/- markers like vim-gitgutter
            keep-plus-minus-markers = true;

            # Line number formatting
            line-numbers-left-format = "{nm:^4}│";
            line-numbers-right-format = "{np:^4}│";

            # Style for removed lines - red background with syntax highlighting
            minus-style = "syntax #3e2e32";
            minus-emph-style = "syntax #5e3e42";
            minus-non-emph-style = "syntax #3e2e32";

            # Style for added lines - green background with syntax highlighting
            plus-style = "syntax #2e3e32";
            plus-emph-style = "syntax #3e5e42";
            plus-non-emph-style = "syntax #2e3e32";

            # Line numbers styling (Catppuccin colors)
            line-numbers-minus-style = "#f38ba8";
            line-numbers-plus-style = "#a6e3a1";
            line-numbers-zero-style = "#6c7086";

            # Unchanged lines keep full syntax highlighting
            zero-style = "syntax";

            # File headers
            file-style = "#89b4fa bold";
            file-decoration-style = "#89b4fa ul";

            # Hunk headers
            hunk-header-style = "file line-number syntax";
            hunk-header-decoration-style = "#6c7086 box";
            hunk-header-file-style = "#89b4fa";
            hunk-header-line-number-style = "#a6e3a1";
          };
        };
      };
    };
  };
}
