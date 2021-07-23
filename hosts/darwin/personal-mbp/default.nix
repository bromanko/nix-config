{ config, lib, pkgs, ... }:

{
  imports = [
    ../../../modules/fonts.nix
    # ../../../home/default.nix
    # ../../../modules/shells.nix
    # ../../../modules/neovim.nix
    # ../../../modules/emacs.nix
    # ../../../modules/kitty.nix
  ];

  networking.computerName = "bromanko Macbook Pro";
  networking.hostName = "bromanko-macbook-pro";

  environment.variables.PROJECTS = "$HOME/Code";
}
