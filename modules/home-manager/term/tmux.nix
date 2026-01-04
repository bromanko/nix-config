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
  whichKeyXdgEnable = pkgs.writeTextFile {
    name = "tmux-which-key-xdg-enable";
    destination = "/enable.tmux";
    executable = true;
    text = ''
      #!/usr/bin/env sh
      set -e
      tmux set -g @tmux-which-key-xdg-enable 1
    '';
  };
  pythonWithYaml = pkgs.python3.withPackages (ps: [ ps.pyyaml ]);
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
          tmux-powerline
          (mkTmuxPlugin {
            pluginName = "tmux-which-key-xdg-enable";
            version = "1";
            rtpFilePath = "enable.tmux";
            src = whichKeyXdgEnable;
          })
          (mkTmuxPlugin {
            pluginName = "tmux-which-key";
            version = "unstable-2024-01-06";
            rtpFilePath = "plugin.sh.tmux";
            src = pkgs.fetchFromGitHub {
              owner = "alexwforsythe";
              repo = "tmux-which-key";
              rev = "1f419775caf136a60aac8e3a269b51ad10b51eb6";
              sha256 = "sha256-X7FunHrAexDgAlZfN+JOUJvXFZeyVj9yu6WRnxMEA8E=";
            };
            postPatch = ''
              substituteInPlace plugin.sh.tmux \
                --replace-fail 'readlink' '${pkgs.coreutils}/bin/readlink' \
                --replace-fail 'realpath' '${pkgs.coreutils}/bin/realpath' \
                --replace-fail 'python3' '${lib.getExe pythonWithYaml}' \
                --replace-fail 'cp "$root_dir/config.example.yaml" "$config_file"' 'cp "$root_dir/config.example.yaml" "$config_file" && chmod u+w "$config_file"' \
                --replace-fail 'cp "$plugin_dir/init.example.tmux" "$init_file"' 'cp "$plugin_dir/init.example.tmux" "$init_file" && chmod u+w "$init_file"'
            '';
            preInstall = ''
              rm -rf plugin/pyyaml
              ln -s ${pkgs.python3.pkgs.pyyaml.src} plugin/pyyaml
            '';
            postInstall = ''
              patchShebangs plugin.sh.tmux plugin/build.py
            '';
          })
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
