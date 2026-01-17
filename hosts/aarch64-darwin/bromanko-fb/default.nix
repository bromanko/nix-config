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
          "/opt/facebook/hg/bin"
          "/opt/facebook/bin/"
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
        activitywatch.enable = true;
        raycast.enable = true;
        multitouch.enable = true;
        autoraise.enable = true;
        aerospace = {
          enable = true;
          windowRules = [
            {
              "if".app-id = "com.google.Chrome";
              run = "move-node-to-workspace 1";
            }
            {
              "if".app-id = "us.zoom.xos";
              run = "move-node-to-workspace 1";
            }
            {
              "if".app-name-regex-substring = "Google Chat";
              run = "move-node-to-workspace 1";
            }
            {
              "if".app-name-regex-substring = "Workchat";
              run = "move-node-to-workspace 6";
            }
            {
              "if".app-name-regex-substring = "Calendar";
              run = "move-node-to-workspace 2";
            }
            {
              "if".app-id = "md.obsidian";
              run = "move-node-to-workspace 2";
            }
            {
              "if".app-name-regex-substring = "Metamate";
              run = "move-node-to-workspace 2";
            }
            {
              "if".app-id = "com.mitchellh.ghostty";
              run = "move-node-to-workspace 3";
            }
            {
              "if".app-id = "com.facebook.fbvscode";
              run = "move-node-to-workspace 3";
            }
            {
              "if".app-id = "com.apple.mail";
              run = "move-node-to-workspace 4";
            }
            {
              "if".app-id = "com.goodsnooze.MacWhisper";
              run = "move-node-to-workspace 6";
            }
          ];
        };
      };
    };
    dev = {
      nodejs.enable = true;
    };
    term = {
      ghostty.enable = true;
      tmux.enable = true;
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
        "bartender"
        "betterdisplay"
        "camo-studio"
        "figma"
        "homerow"
        "istat-menus"
        "lunar"
        "macwhisper"
        "signal"
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
