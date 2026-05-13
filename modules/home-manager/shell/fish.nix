{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.fish;
in
{
  options.modules.shell.fish = with types; {
    enable = mkBoolOpt false;

    projectsPath = mkOpt' str "$HOME/Code" "Directory containing project files.";

    extraPaths = mkOption {
      type = listOf str;
      example = "$HOME/bin";
      default = [ ];
      description = "Additional paths to add to <envar>PATH</envar.";
    };

    rebuildTarget = mkOption {
      type = nullOr str;
      default = null;
      description = "Darwin flake host name to use for rebuild! when it differs from hostname.";
    };
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        sessionVariables = {
          SHELL = "${pkgs.fish}/bin/fish";
          PROJECTS = cfg.projectsPath;
        };
      };

      programs.fish = {
        enable = true;

        functions = {
          vterm_printf = ''
            function vterm_printf;
                if begin; [  -n "$TMUX" ]  ; and  string match -q -r "screen|tmux" "$TERM"; end
                    # tell tmux to pass the escape sequences through
                    printf "\ePtmux;\e\e]%s\007\e\\" "$argv"
                else if string match -q -- "screen*" "$TERM"
                    # GNU screen (screen, screen-256color, screen-256color-bce)
                    printf "\eP\e]%s\007\e\\" "$argv"
                else
                    printf "\e]%s\e\\" "$argv"
                end
            end
          '';
          vterm_prompt_end = "vterm_printf '51;A'(whoami)'@'(hostname)':'(pwd)";
          gi = "curl -sL https://www.toptal.com/developers/gitignore/api/$argv";
          multicd = "echo cd (string repeat -n (math (string length -- $argv[1]) - 1) ../)";
          timg = ''
            # Auto-select kitty protocol when in tmux for better compatibility
            if test -n "$TMUX"
              command timg -p kitty $argv
            else
              command timg $argv
            end
          '';
        };

        shellAbbrs = {
          S = "sudo";
          e = "$EDITOR";
          c = "cd $PROJECTS/";
        };

        shellAliases = {
          "reload!" = "exec fish";
          "less" = "less -R";
        };

        interactiveShellInit = ''
          # SSH keys may live in a forwarded agent whose concrete socket path
          # changes on reconnect. Refresh a stable symlink from fresh SSH/ET
          # agent sockets, then point remote tmux panes at that stable path.
          # Do not blindly prefer an existing symlink: after sleep/wake the
          # socket file may still exist while the agent connection is stale.
          set -l stable_ssh_auth_sock "$HOME/.ssh/agent.sock"
          set -l has_current_ssh_auth_sock 0

          if test -n "$SSH_AUTH_SOCK"; and test -S "$SSH_AUTH_SOCK"
              set has_current_ssh_auth_sock 1
          end

          if test "$has_current_ssh_auth_sock" = 1; and test "$SSH_AUTH_SOCK" != "$stable_ssh_auth_sock"; and begin
              set -q SSH_CONNECTION; or string match -q -- "*/et_forward_sock_*/sock" "$SSH_AUTH_SOCK"
          end
              mkdir -p "$HOME/.ssh"
              ln -sfn "$SSH_AUTH_SOCK" "$stable_ssh_auth_sock"
              set -gx SSH_AUTH_SOCK "$stable_ssh_auth_sock"
          else if test -n "$TMUX"; and test -S "$stable_ssh_auth_sock"
              set -gx SSH_AUTH_SOCK "$stable_ssh_auth_sock"
          end
          fish_vi_key_bindings
          set fish_cursor_default block
          set fish_cursor_insert line
          # Force needed for wezterm. See https://github.com/wez/wezterm/discussions/4670
          set fish_vi_force_cursor 1

          # add extra paths to $PATH
          ${concatStrings (
            map (path: ''
              fish_add_path "${path}"
            '') cfg.extraPaths
          )}

          abbr --add dotdot --regex '^\.\.+$' --function multicd

          # vterm
          if test -n "$INSIDE_EMACS"
              functions --copy fish_prompt vterm_old_fish_prompt
              function fish_prompt --description 'Write out the prompt; do not replace this. Instead, put this at end of your file.'
                  # Remove the trailing newline from the original prompt. This is done
                  # using the string builtin from fish, but to make sure any escape codes
                  # are correctly interpreted, use %b for printf.
                  printf "%b" (string join "\n" (vterm_old_fish_prompt))
                  vterm_prompt_end
              end
          end
        '';
      };
    };
  };
}
