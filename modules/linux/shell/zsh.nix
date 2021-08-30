{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  config = {
    home-manager.users."${config.user.name}" = {
      programs.zsh = {
        shellAliases = {
          pbcopy = "xclip -selection clipboard";
          pbpaste = "xclip -selection clipboard -o";
        };
      };
    };

    # Completion for system packages
    environment.pathsToLink = [ "/share/zsh" ];
  };
}
