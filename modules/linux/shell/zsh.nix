{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  config = {
    # Completion for system packages
    environment.pathsToLink = [ "/share/zsh" ];
  };
}
