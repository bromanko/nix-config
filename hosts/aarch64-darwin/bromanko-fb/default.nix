{ pkgs, config, lib, ... }:

with lib;
with lib.my; {
  modules = {
    shell = {
      commonPkgs.enable = true;
      zsh = {
        enable = true;
        extraPaths = [
          "$HOME/homebrew/bin"
          "/opt/facebook/bin"
          "/opt/facebook/hg/bin"
          "$HOME/.emacs.d/bin"
        ];
      };
      bat.enable = true;
      git.enable = true;
      starship.enable = true;
      fzf.enable = true;
      direnv.enable = true;
      exa.enable = true;
      fd.enable = true;
    };
    desktop = {
      fonts.enable = true;
      apps = {
        raycast.enable = true;
        espanso.enable = true;
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
        "federico-terzi/espanso"
      ];
      casks = [
        "1password"
        "bartender"
        "betterdisplay"
        "camo-studio"
        "choosy"
        "istat-menus"
        "lunar"
        "raycast"
        "signal"
        "spotify"
      ];
      brews = [ "espanso" ];
      masApps = {
        Amphetamine = 937984704;
        Fantastical = 975937182;
        Keynote = 409183694;
        Numbers = 409203825;
        Pages = 409201541;
        "Unsplash Wallpapers" = 1284863847;
      };
    };
  };

  home-manager = { sharedModules = [{ manual.manpages.enable = false; }]; };
  services.nix-daemon.enable = true;
}
