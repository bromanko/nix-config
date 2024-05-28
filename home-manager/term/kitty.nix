{ config, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.term.kitty;

in {
  config = mkIf cfg.enable {
    programs.kitty = {
      enable = true;
      font = {
        name = "MonaspiceAr Nerd Font Propo";
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
        theme = "Catppuccin-Mocha";
        cursor_shape = "beam";
        scrollback_lines = 10000;
        open_url_modifiers = "cmd";
        copy_on_select = true;
        remember_window_size = true;
        tab_bar_style = "powerline";
        macos_hide_titlebar = true;
        macos_option_as_alt = true;
      };
    };
  };
}
