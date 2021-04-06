{ config, pkgs, lib, ... }:

{
  programs.doom-emacs = {
    enable = true;
    # TODO This is not appropriate for linux
    package = pkgs.emacsMacport;
    doomPrivateDir = ./programs/emacs/doom.d;
  };
}
