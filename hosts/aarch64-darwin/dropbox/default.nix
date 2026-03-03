{
  pkgs,
  lib,
  inputs,
  ...
}:

with lib;
with lib.my;
{
  networking.hostName = "HY3LWT2P5P";

  modules = {
    nix = {
      system.enable = "determinate";
      dev.enable = true;
    };
    homeage = {
      enable = false;
    };
    shell = {
      commonPkgs.enable = true;
      ssh.enable = true;
      openssh.enable = true;
      fish = {
        enable = true;
        extraPaths = [
          "$HOME/bin"
        ];
      };
      bat.enable = true;
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
        raycast.enable = true;
        claude.enable = true;
        aerospace = {
          enable = true;
          windowRules = [
            {
              "if".app-id = "com.google.Chrome";
              run = "move-node-to-workspace 1";
            }
            {
              "if".app-id = "com.tinyspeck.slackmacgap";
              run = "move-node-to-workspace 1";
            }
            {
              "if".app-id = "us.zoom.xos";
              run = "move-node-to-workspace 1";
            }
            {
              "if".app-id = "com.apple.Calendar";
              run = "move-node-to-workspace 2";
            }
            {
              "if".app-id = "md.obsidian";
              run = "move-node-to-workspace 2";
            }
            {
              "if".app-id = "com.openai.chat";
              run = "move-node-to-workspace 2";
            }
            {
              "if".app-id = "com.mitchellh.ghostty";
              run = "move-node-to-workspace 3";
            }
            {
              "if".app-id = "com.microsoft.VSCode";
              run = "move-node-to-workspace 3";
            }
            {
              "if".app-id = "com.apple.mail";
              run = "move-node-to-workspace 4";
            }
            {
              "if".app-id = "com.apple.finder";
              run = "move-node-to-workspace 6";
            }
            {
              "if".app-id = "com.apple.Music";
              run = "move-node-to-workspace 7";
            }
            {
              "if".app-id = "com.goodsnooze.MacWhisper";
              run = "move-node-to-workspace 7";
            }
          ];
        };
      };
    };
    dev = {
      nodejs.enable = true;
      claude-code.enable = true;
      pi.enable = true;
    };
    term = {
      ghostty.enable = true;
      tmux.enable = true;
    };
    editor = {
      default = "nvim";
      visual = "code --wait";
      neovim.enable = true;
      zed.enable = true;
    };

    homebrew = {
      enable = true;
      taps = [
        "homebrew/services"
      ];
      casks = [
        "badgeify"
        "bartender"
        "camo-studio"
        "figma"
        "hazeover"
        "homerow"
        "obsidian"
        "istat-menus"
        "macwhisper"
      ];
    };
  };
  hm = {
    home = {
      packages = with pkgs; [
        iina
      ];
    };
  };
}
