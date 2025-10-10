{ lib, pkgs, ... }:

{
  home = {
    homeDirectory = lib.mkForce "/home/bromanko.linux";
    packages = with pkgs; [ ncurses ];
  };

  modules = {
    nix = {
      system.enable = "determinate";
      dev.enable = true;
    };
    homeage = {
      enable = true;
    };
    shell = {
      commonPkgs.enable = true;
      openssh.enable = true;
      ssh.enable = true;
      fish.enable = true;
      bat.enable = true;
      git.enable = true;
      jujutsu.enable = true;
      starship.enable = true;
      fzf.enable = true;
      direnv.enable = true;
      exa.enable = true;
      fd.enable = true;
    };
    dev = {
      elixir.enable = true;
      idea.enable = true;
      psql.enable = true;
      nodejs.enable = true;
      codex.enable = true;
      claude-code.enable = true;
      lima.enable = true;
    };
    editor = {
      default = "nvim";
      neovim.enable = true;
    };
  };
}
