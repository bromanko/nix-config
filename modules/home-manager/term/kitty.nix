{ lib, config, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.term.kitty;
in
{
  options.modules.term.kitty = with types; {
    enable = mkBoolOpt false;
    fontSize = mkOption {
      type = int;
      example = "16";
      description = "The size of the font.";
      default = 14;
    };
  };

  config = mkIf cfg.enable {
    hm = {
      programs.kitty = {
        enable = true;
        font = {
          name = "MonaspiceAr Nerd Font Mono Light";
          size = config.modules.term.kitty.fontSize;
        };
        theme = "Catppuccin-Mocha";
        shellIntegration = {
          enableZshIntegration = config.modules.shell.zsh.enable;
          enableFishIntegration = config.modules.shell.fish.enable;
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
          hide_window_decorations = "titlebar-only";
          macos_option_as_alt = true;
          window_padding_width = 10;
          window_margin_width = "10 0 0 0";
        };
      };
    };
  };
}
