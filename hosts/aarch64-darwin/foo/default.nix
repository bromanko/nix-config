{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  modules = {
    shell.zsh.enable = true;
    desktop.apps.espanso.enable = true;
    desktop.fonts.enable = true;
  };
}
