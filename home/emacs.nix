{ config, pkgs, lib, home-manager, ... }:

{
  programs.emacs = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.emacsMacport else pkgs.emacs;
  };
  home-manager.home.file.".doom.d".source = ./programs/emacs/doom.d;
}
