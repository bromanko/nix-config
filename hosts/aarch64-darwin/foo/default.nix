{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  modules = {
    shell.zsh.enable = true;
    desktop.apps.espanso.enable = true;
    desktop.fonts.enable = true;
    editor.default = "foop";
    editor.neovim.enable = true;
    editor.emacs.enable = true;
    shell = { openssh.enable = true; };
    term = { kitty.enable = true; };
  };
}
