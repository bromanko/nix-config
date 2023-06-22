{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.zsh;
in {
  config = mkIf cfg.enable {
    programs.zsh.enable = true;

    home-manager.users."${config.user.name}" = {
      programs.zsh = {
        shellAliases = {
          pbcopy = "xclip -selection clipboard";
          pbpaste = "xclip -selection clipboard -o";
        };
      };
    };

    environment = {
      # Completion for system packages
      pathsToLink = [ "/share/zsh" ];
      shells = [ pkgs.zsh ];
    };
  };
}
