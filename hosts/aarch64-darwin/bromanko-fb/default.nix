{ pkgs, config, lib, ... }:

with lib;
with lib.my; {
  modules = {
    shell = {
      commonPkgs.enable = true;
      ssh.enable = true;
      fish = {
        enable = true;
        extraPaths = [
          "$HOME/homebrew/bin"
          "/opt/facebook/bin"
          "/opt/facebook/hg/bin"
          "$HOME/.emacs.d/bin"
        ];
      };
      bat.enable = true;
      git = {
        enable = true;
        userEmail = "bromanko@meta.com";
      };
      starship.enable = true;
      fzf.enable = true;
      direnv.enable = true;
      exa.enable = true;
      fd.enable = true;
    };
    desktop = {
      fonts.enable = true;
      dictionaries.enable = true;
      apps = {
        "1Password".enable = true;
        raycast.enable = true;
        hammerspoon.enable = true;
        vimari.enable = true;
      };
    };
    dev = {
      nix.enable = true;
      nodejs.enable = true;
      idea.enable = true;
    };
    term = { kitty.enable = true; };
    editor = {
      neovim.enable = true;
      emacs.enable = true;
    };

    homebrew = {
      enable = true;
      brewPrefix = "$HOME/homebrew/bin";
      taps = [
        "homebrew/cask"
        "homebrew/cask-versions"
        "homebrew/core"
        "homebrew/services"
      ];
      casks = [
        "bartender"
        "betterdisplay"
        "camo-studio"
        "figma"
        "istat-menus"
        "lunar"
        "signal"
        "spotify"
        "kindaVim"
      ];
      masApps = {
        Amphetamine = 937984704;
        Keynote = 409183694;
        Numbers = 409203825;
        Pages = 409201541;
      };
    };
  };

  hm = { home = { packages = with pkgs; [ obsidian ]; }; };
  services.nix-daemon.enable = true;
}
