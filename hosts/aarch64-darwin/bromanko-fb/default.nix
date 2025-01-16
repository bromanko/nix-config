{ pkgs, lib, ... }:

with lib;
with lib.my;
{
  modules = {
    shell = {
      commonPkgs.enable = true;
      ssh.enable = true;
      fish = {
        enable = true;
        extraPaths = [
          "$HOME/homebrew/bin"
          "$HOME/.config/emacs/bin"
          "$HOME/.nix-profile/bin"
        ];
      };
      bat.enable = true;
      git.enable = true;
      jujutsu.enable = true;
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
        synergy = {
          enable = true;
          mode = "server";
        };
      };
    };
    dev = {
      nix.enable = true;
      nodejs.enable = true;
      idea.enable = true;
    };
    term = {
      kitty.enable = true;
      wezterm.enable = true;
      ghostty.enable = true;
    };
    editor = {
      neovim.enable = true;
      emacs.enable = true;
      visual = "code-fb -w";
    };

    homebrew = {
      enable = true;
      brewPrefix = "/Users/bromanko/homebrew/bin";
      taps = [
        "homebrew/cask-versions"
        "homebrew/services"
      ];
      casks = [
        "betterdisplay"
        "camo-studio"
        "figma"
        "istat-menus"
        "jordanbaird-ice"
        "lunar"
        "signal"
        "spotify"
        "google-drive"
        "onedrive"
      ];
      masApps = {
        Amphetamine = 937984704;
        Keynote = 409183694;
        Numbers = 409203825;
        Pages = 409201541;
      };
    };
  };

  hm = {
    home = {
      packages = with pkgs; [
        obsidian
        pandoc
        my.homerow
      ];
    };
  };
  services.nix-daemon.enable = true;
}
