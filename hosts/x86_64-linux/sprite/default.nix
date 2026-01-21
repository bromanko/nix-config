{
  lib,
  pkgs,
  ...
}:

{
  home = {
    username = lib.mkForce "sprite";
    homeDirectory = lib.mkForce "/home/sprite";
    packages = with pkgs; [
      ncurses
      curl
      wget
      unzip
      htop
    ];
  };

  programs.fish = {
    shellAliases = {
      rebuild = "nix build --refresh github:bromanko/nix-config#homeManagerConfigurations.sprite.activationPackage && ./result/activate";
    };
    interactiveShellInit = ''
      # Set tmux pane option to indicate we're in a sprite
      if test -d /.sprite; and set -q TMUX
        set -l sprite_name (hostname -s)
        tmux set-option -p @pane_sprite "$sprite_name" 2>/dev/null
      end
    '';
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
    dev = { };
    editor = {
      default = "nvim";
      neovim.enable = true;
    };
  };
}
