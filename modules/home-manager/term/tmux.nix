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

  tmux-rename-session-repo = pkgs.writeShellScriptBin "tmux-rename-session-repo" ''
    pane_path=$(tmux display-message -p '#{pane_current_path}')
    repo_root=$(git -C "$pane_path" rev-parse --show-toplevel 2>/dev/null \
      || jj -R "$pane_path" root 2>/dev/null \
      || echo "$pane_path")
    tmux rename-session "$(basename "$repo_root")"
  '';

  # Remote entrypoint for `et -c 'et-attach [session]' host`.
  # Loads the remote secret-proxy env file without baking secrets into Nix or
  # the local et command, then attaches to or creates a tmux session.
  et-attach = pkgs.writeShellScriptBin "et-attach" ''
    set -euo pipefail

    usage() {
      cat <<'USAGE'
    usage: et-attach [SESSION]

    Attach to or create a tmux session after loading KEY=VALUE entries from
    ET_ENV_FILE, defaulting to ~/.config/secret-proxy/secrets.env.
    USAGE
    }

    trim() {
      local value="$1"
      value="''${value#"''${value%%[![:space:]]*}"}"
      value="''${value%"''${value##*[![:space:]]}"}"
      printf '%s' "$value"
    }

    merge_word() {
      local words="$1"
      local word="$2"

      case " $words " in
        *" $word "*) printf '%s' "$words" ;;
        *) printf '%s %s' "$words" "$word" ;;
      esac
    }

    session="''${ET_TMUX_SESSION:-main}"
    case "''${1:-}" in
      -h | --help)
        usage
        exit 0
        ;;
    esac

    if (( $# > 0 )); then
      session="$1"
      shift
    fi

    if (( $# > 0 )); then
      echo "et-attach: unexpected arguments: $*" >&2
      usage >&2
      exit 2
    fi

    env_file="''${ET_ENV_FILE:-$HOME/.config/secret-proxy/secrets.env}"
    secret_names=""

    if [[ -r "$env_file" ]]; then
      while IFS= read -r line || [[ -n "$line" ]]; do
        line="$(trim "$line")"

        [[ -z "$line" || "''${line:0:1}" == "#" ]] && continue
        [[ "$line" != *"="* ]] && continue

        key="$(trim "''${line%%=*}")"
        value="$(trim "''${line#*=}")"

        if [[ ! "$key" =~ ^[A-Za-z_][A-Za-z0-9_]*$ ]]; then
          continue
        fi

        if [[ ''${#value} -ge 2 ]]; then
          first="''${value:0:1}"
          last="''${value: -1}"
          if { [[ "$first" == '"' ]] && [[ "$last" == '"' ]]; } || { [[ "$first" == "'" ]] && [[ "$last" == "'" ]]; }; then
            value="''${value:1}"
            value="''${value%?}"
          fi
        fi

        export "$key=$value"
        secret_names="$(merge_word "$secret_names" "$key")"
      done < "$env_file"
    elif [[ -n "''${ET_ENV_FILE:-}" ]]; then
      echo "et-attach: ET_ENV_FILE is not readable: $env_file" >&2
      exit 1
    fi

    tmux_bin="${pkgs.tmux}/bin/tmux"
    default_update_environment="DISPLAY KRB5CCNAME MSYSTEM SSH_ASKPASS SSH_AUTH_SOCK SSH_AGENT_PID SSH_CONNECTION WINDOWID XAUTHORITY"
    current_update_environment="$("$tmux_bin" show-options -gqv update-environment 2>/dev/null || true)"

    if [[ -z "$current_update_environment" ]]; then
      current_update_environment="$default_update_environment"
    fi

    update_environment="$current_update_environment"
    for name in $secret_names; do
      update_environment="$(merge_word "$update_environment" "$name")"
    done

    exec "$tmux_bin" set-option -g update-environment "$update_environment" \; new-session -A -s "$session"
  '';

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
      # Add smug and tmux-dashboard packages
      home.packages = [
        pkgs.smug
        pkgs.my.tmux-dashboard
        tmux-rename-session-repo
        et-attach
      ];

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
          {
            plugin = yank;
            extraConfig = ''
              set -g @yank_action 'copy-pipe-no-clear'
            '';
          }
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
          set -g extended-keys-format csi-u
          set -as terminal-features 'xterm*:extkeys'

          # Stay in copy mode after mouse drag selection
          bind-key -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-selection-no-clear

          # Allow passthrough sequences for inline images and other terminal features
          set -g allow-passthrough on

          # Allow applications to read the clipboard via OSC 52
          # (default "external" only allows writes; "on" allows reads too)
          set -g set-clipboard on

          # Allow cursor shape changes to pass through (fixes fish vi-mode cursor)
          set -ga terminal-overrides '*:Ss=\E[%p1%d q:Se=\E[ q'

          # Session dashboard (Prefix + s) / plain tree picker (Prefix + S)
          bind s display-popup -E -w 80% -h 70% -T " Sessions " "tmux-dashboard"
          bind S choose-tree -Zs

          # Show keybindings help (Prefix + ?)
          bind ? list-keys

          # Reload config
          bind r source-file ~/.config/tmux/tmux.conf \; display "Config reloaded"

          # Rename current window to active pane's process name (Prefix + M)
          bind M rename-window "#{pane_current_command}"

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

          # Advertise Kitty graphics protocol support for terminals that support it
          set -ga terminal-features "*:hyperlinks:clipboard:strikethrough:sixel:graphics"

          # Set window notifications
          setw -g monitor-activity on
          set -g visual-activity off
          set -g window-status-activity-style "none"

          # Pane focus styling - dim inactive panes, highlight active border
          set -g window-style 'fg=colour245,bg=colour235'
          set -g window-active-style 'fg=terminal,bg=terminal'
          set -g pane-active-border-style 'fg=colour39'

          # pi tmux-titles extension sets window names via escape sequences
          set -g automatic-rename off
          set -g allow-rename on
        '';
      };
    };
  };
}
