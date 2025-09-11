{ pkgs, lib, ... }:

with lib;
with lib.my;
{
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
      ssh.enable = true;
      fish = {
        enable = true;
        extraPaths = [
          "/Users/bromanko/homebrew/bin"
          "/Users/bromanko/.nix-profile/bin"
        ];
      };
      bat.enable = true;
      git = {
        enable = true;
      };
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
      nodejs.enable = true;
      idea.enable = true;
    };
    term = {
      ghostty.enable = true;
    };
    editor = {
      neovim.enable = true;
      visual = "code-fb -w";
    };

    homebrew = {
      enable = true;
      brewPrefix = "/Users/bromanko/homebrew/bin";
      casks = [
        "badgeify"
        "betterdisplay"
        "camo-studio"
        "figma"
        "homerow"
        "istat-menus"
        "jordanbaird-ice"
        "lunar"
        "signal"
        "google-drive"
        "obsidian"
        "onedrive"
        "steermouse"
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
        pandoc
        eternal-terminal
      ];
    };
  };
}
