{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.term.tmux;
in
{
  options.modules.term.tmux = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      xdg.configFile = {
        "tmux-powerline/config.sh".source = ../../../configs/tmux-powerline/config.sh;
        "tmux-powerline/themes/custom.sh".source = ../../../configs/tmux-powerline/themes/custom.sh;
      };

      programs.tmux = {
        enable = true;
        shell = "${pkgs.fish}/bin/fish";
        terminal = "screen-256color";
        historyLimit = 50000;
        keyMode = "vi";
        mouse = true;
        prefix = "C-a";
        escapeTime = 0;

        plugins = with pkgs.tmuxPlugins; [
          sensible
          yank
          {
            plugin = catppuccin;
            extraConfig = ''
              set -g @catppuccin_flavour 'mocha'
            '';
          }
        ];

        extraConfig = ''
          # Use user's default shell
          set-option -g default-shell $SHELL

          # Show keybindings help (Prefix + ?)
          bind ? list-keys

          # Reload config
          bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"

          # Split panes using | and -
          bind | split-window -h
          bind - split-window -v
          unbind '"'
          unbind %

          # Switch panes using Alt-arrow without prefix
          bind -n M-Left select-pane -L
          bind -n M-Right select-pane -R
          bind -n M-Up select-pane -U
          bind -n M-Down select-pane -D

          # Enable true color support
          set -ga terminal-overrides ",*256col*:Tc"

          # Set window notifications
          setw -g monitor-activity on
          set -g visual-activity off
        '';
      };
    };
  };
}
