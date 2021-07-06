{ config, pkgs, lib, ... }:

{
  programs.emacs = {
    enable = true;
    package = if pkgs.stdenv.isDarwin then pkgs.emacsMacport else pkgs.emacs;
  };
  home.file.".doom.d".source = ./programs/emacs/doom.d;
}
