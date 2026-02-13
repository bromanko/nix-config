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

  # Default smug project for development work
  defaultSmugProject = {
    session = "\${session}";
    root = "\${root}";
    windows = [
      { name = "shell"; }
      {
        name = "jjui";
        commands = [ "jjui" ];
      }
      {
        name = "claude";
        commands = [ "claude --resume" ];
      }
    ];
  };

  # Lima variant - same layout but runs inside the Lima dev VM
  # Uses lima_root for the VM-translated path
  limaSmugProject = {
    session = "\${session}";
    root = "\${root}";
    windows = [
      {
        name = "shell";
        commands = [ "limassh --workdir \${lima_root}" ];
      }
      {
        name = "jjui";
        commands = [ "limassh --workdir \${lima_root} -- jjui" ];
      }
      {
        name = "claude";
        commands = [ "limassh --workdir \${lima_root} -- claude --resume" ];
      }
    ];
  };

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
      # Add smug package
      home.packages = [ pkgs.smug ];

      programs.fish.shellAliases = {
        # Smug aliases
        smd = "smug start dev session=(basename (pwd)) root=(pwd)"; # Start dev session named after current directory
        smstop = "smug stop dev session=(basename (pwd))"; # Stop dev session for current directory
        sml = "smug list"; # List smug projects
      };

      programs.fish.functions = {
        # Start dev session in Lima VM, translating host path to VM path
        smdl = ''
          set -l host_home $HOME
          set -l lima_home /home/bromanko.linux
          set -l host_root (pwd)
          set -l lima_root (string replace "$host_home" "$lima_home" "$host_root")
          smug start dev-lima session=(basename (pwd)) root="$host_root" lima_root="$lima_root"
        '';
      };

      xdg.configFile = {
        "tmux-powerline/config.sh".source = ../../../configs/tmux-powerline/config.sh;
        "tmux-powerline/themes/custom.sh".source = ../../../configs/tmux-powerline/themes/custom.sh;
        "tmux-powerline/segments/hostname_not_sprite.sh" = {
          source = ../../../configs/tmux-powerline/segments/hostname_not_sprite.sh;
          executable = true;
        };
        "tmux-powerline/segments/sprite.sh" = {
          source = ../../../configs/tmux-powerline/segments/sprite.sh;
          executable = true;
        };
        "tmux-powerline/segments/lima.sh" = {
          source = ../../../configs/tmux-powerline/segments/lima.sh;
          executable = true;
        };

        # Default smug project configuration
        "smug/dev.yml".source = (pkgs.formats.yaml { }).generate "dev.yml" defaultSmugProject;
        "smug/dev-lima.yml".source = (pkgs.formats.yaml { }).generate "dev-lima.yml" limaSmugProject;

        # tmux-which-key configuration
        "tmux/plugins/tmux-which-key/config.yaml".source = ../../../configs/tmux-which-key/config.yaml;
      };

      programs.tmux = {
        enable = true;
        shell = "${pkgs.fish}/bin/fish";
        terminal = "tmux-256color";
        historyLimit = 50000;
        keyMode = "vi";
        mouse = true;
        prefix = "C-a";
        escapeTime = 0;

        plugins = with pkgs.tmuxPlugins; [
          sensible
          yank
          {
            plugin = resurrect;
            extraConfig = ''
              set -g @resurrect-capture-pane-contents 'on'
              set -g @resurrect-strategy-default 'blank'
            '';
          }
          {
            plugin = continuum;
            extraConfig = ''
              set -g @continuum-restore 'on'
              set -g @continuum-save-interval '15'
            '';
          }
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
          # Override tmux-sensible's reattach-to-user-namespace default-command (unnecessary on modern macOS)
          set -g default-command ""

          # Enable extended keys (Kitty keyboard protocol) so apps like pi
          # can detect modifier keys (e.g. Shift+Enter for newline)
          set -g extended-keys on
          set -as terminal-features 'xterm*:extkeys'

          # Allow cursor shape changes to pass through (fixes fish vi-mode cursor)
          set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'

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
          set -g window-status-activity-style "none"

          # pi tmux-titles extension sets window names via escape sequences
          set -g automatic-rename off
          set -g allow-rename on
        '';
      };
    };
  };
}
