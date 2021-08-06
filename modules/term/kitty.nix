{ config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.term.kitty;

in {
  options.modules.term.kitty = with types; { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}" = {
      programs.kitty = {
        enable = true;
        font = {
          name = "FantasqueSansMono Nerd Font";
          size = 16;
        };
        keybindings = {
          "cmd+up" = "scroll_line_up";
          "cmd+down" = "scroll_line_down";
          "kitty_mod+f" = "show_scrollback";
          "cmd+t" = "new_tab";
          "cmd+w" = "close_tab";
          "cmd+1" = "goto_tab 1";
          "cmd+2" = "goto_tab 2";
          "cmd+3" = "goto_tab 3";
          "cmd+4" = "goto_tab 4";
          "cmd+5" = "goto_tab 5";
          #
          "kitty_mod+e" = "kitten hints";
          "kitty_mod+p>f" = "kitten hints --type path --program -";
          "kitty_mod+p>shift+f" = "kitten hints --type path";
        };
        settings = {
          cursor_shape = "beam";
          scrollback_lines = 10000;
          open_url_modifiers = "cmd";
          copy_on_select = true;
          remember_window_size = true;
          tab_bar_style = "powerline";
          macos_hide_titlebar = true;
          macos_option_as_alt = true;

          # Color Scheme
          background = "#2d2a2e";
          foreground = "#e3e1e4";

          selection_background = "#423f46";
          selection_foreground = "#e3e1e4";

          cursor = "#e3e1e4";
          cursor_text_color = "background";

          # active_tab_background #2d2a2e
          # active_tab_foreground #e3e1e4
          # active_tab_font_style bold
          # inactive_tab_background #2d2a2e
          # inactive_tab_foreground #e3e1e4
          # inactive_tab_font_style normal

          # Black
          color0 = "#1a181a";
          color8 = "#848089";

          # Red
          color1 = "#f85e84";
          color9 = "#f85e84";

          # Green
          color2 = "#9ecd6f";
          color10 = "#9ecd6f";

          # Yellow
          color3 = "#e5c463";
          color11 = "#e5c463";

          # Blue
          color4 = "#7accd7";
          color12 = "#7accd7";

          # Magenta
          color5 = "#ab9df2";
          color13 = "#ab9df2";

          # Cyan
          color6 = "#ef9062";
          color14 = "#ef9062";

          # White
          color7 = "#e3e1e4";
          color15 = "#e3e1e4";
        };
      };

      programs.zsh.shellAliases =
        mkIf config.modules.shell.zsh.enable { ssh = "kitty +kitten ssh"; };
    };
  };
}
