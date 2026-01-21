{
  lib,
  pkgs,
  ...
}:

{
  home = {
    packages = with pkgs; [
      ncurses
      curl
      wget
      unzip
      htop
    ];
  };

  programs.fish.shellAliases = {
    rebuild = "nix build --refresh github:bromanko/nix-config#homeManagerConfigurations.sprite.activationPackage && ./result/activate";
  };

  modules = {
    nix = {
      system.enable = "determinate";
      dev.enable = true;
    };
    shell = {
      commonPkgs.enable = true;
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
      claude-code.enable = true;
    };
    editor = {
      default = "nvim";
      neovim.enable = true;
    };
  };
}
