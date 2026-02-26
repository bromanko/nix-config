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
  config = mkIf cfg.enable {
    programs.fish.enable = true;

    home-manager.users."${config.user.name}" = {
      programs.fish = {
        functions = {
          # OSC 52 clipboard helpers — works over SSH, in tmux, and in
          # headless VMs as long as the terminal emulator supports OSC 52
          # (Kitty, Ghostty, iTerm2, WezTerm, etc.).
          #
          # pbcopy sends a plain OSC 52 sequence. Inside tmux (with
          # set-clipboard on) tmux both forwards it to the outer terminal
          # AND saves the content in its paste buffer, which lets pbpaste
          # retrieve it via `tmux save-buffer`.
          pbcopy = ''
            read -z -l data
            set -l encoded (printf '%s' $data | base64 | tr -d '\n')
            printf '\e]52;c;%s\a' $encoded
          '';
          pbpaste = ''
            if test -n "$TMUX"
              tmux save-buffer -
            else
              echo "pbpaste: only supported inside tmux on a headless VM" >&2
              return 1
            end
          '';
        };
      };
    };

    environment = {
      pathsToLink = [ "/share/fish" ];
      shells = [ pkgs.fish ];
    };
  };
}
