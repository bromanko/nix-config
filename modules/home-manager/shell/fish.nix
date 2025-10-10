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
        };

        shellAbbrs = {
          S = "sudo";
          e = "$EDITOR";
          c = "cd $PROJECTS/";
        };

        shellAliases = {
          "reload!" = "source ~/.config/fish/config.fish";
          "less" = "less -R";
          "dev" = "limactl shell --shell /home/bromanko.linux/.nix-profile/bin/fish lima-dev";
        };

        interactiveShellInit = ''
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
          functions --copy fish_prompt vterm_old_fish_prompt
          function fish_prompt --description 'Write out the prompt; do not replace this. Instead, put this at end of your file.'
              # Remove the trailing newline from the original prompt. This is done
              # using the string builtin from fish, but to make sure any escape codes
              # are correctly interpreted, use %b for printf.
              printf "%b" (string join "\n" (vterm_old_fish_prompt))
              vterm_prompt_end
          end
        '';
      };
    };
  };
}
