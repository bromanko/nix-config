{ config, pkgs, lib, ... }:

{
  programs.doom-emacs =
    {
      enable = true;
      doomPrivateDir = ./programs/emacs/doom.d;
      emacsPackage = if pkgs.stdenv.isDarwin then pkgs.emacsMacport else pkgs.emacs;
    };
}
