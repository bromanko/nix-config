{ config, lib, pkgs, ... }:

{
  modules = {
    nix = {
      enable = true;
      dev.enable = true;
    };
    shell = {
      commonPkgs.enable = true;
      openssh.enable = true;
      zsh.enable = true;
      bat.enable = true;
      git.enable = true;
      starship.enable = true;
      fzf.enable = true;
      direnv.enable = true;
      exa.enable = true;
      fd.enable = true;
    };
    dev = {
      nodejs.enable = true;
    };
    editor = {
      neovim.enable = true;
    };
  };
}
