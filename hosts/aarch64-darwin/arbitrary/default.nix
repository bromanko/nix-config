{
  pkgs,
  lib,
  inputs,
  ...
}:

let
  brewPath = "/opt/homebrew/bin";
in
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
      openssh.enable = true;
      fish = {
        enable = true;
        extraPaths = [
          "$HOME/bin"
          "$HOME/.config/emacs/bin"
          brewPath
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
      llm.enable = true;
      gemini.enable = true;
    };
    desktop = {
      fonts.enable = true;
      dictionaries.enable = true;
      apps = {
        raycast.enable = true;
        "1Password".enable = true;
        vscode.enable = true;
        claude.enable = true;
        multitouch.enable = true;
        aerospace = {
          enable = true;
          windowRules = [
            {
              "if".app-id = "app.zen-browser.zen";
              run = "move-node-to-workspace 1";
            }
            {
              "if".app-id = "dev.zed.Zed-Preview";
              run = "move-node-to-workspace 2";
            }
            {
              "if".app-id = "com.mitchellh.ghostty";
              run = "move-node-to-workspace 3";
            }
            {
              "if".app-id = "com.apple.MobileSMS";
              run = "move-node-to-workspace 4";
            }
            {
              "if".app-id = "com.apple.mail";
              run = "move-node-to-workspace 4";
            }
            {
              "if".app-id = "com.openai.chat";
              run = "move-node-to-workspace 5";
            }
            {
              "if".app-id = "com.anthropic.claudefordesktop";
              run = "move-node-to-workspace 5";
            }
            {
              "if" = {
                app-id = "com.raycast.macos";
                window-title-regex-substring = "AI Chat";
              };
              run = "move-node-to-workspace 5";
            }
            {
              "if".app-id = "com.1password.1password";
              run = "move-node-to-workspace 6";
            }
            {
              "if".app-id = "com.apple.finder";
              run = "move-node-to-workspace 6";
            }
            {
              "if".app-id = "com.apple.Music";
              run = "move-node-to-workspace 7";
            }
          ];
        };
        autoraise.enable = true;
      };
    };
    dev = {
      elixir.enable = true;
      idea.enable = true;
      psql.enable = true;
      docker.enable = true;
      nodejs.enable = true;
      aider-chat.enable = true;
      codex.enable = true;
      claude-code.enable = true;
      lima.enable = true;
    };
    term = {
      wezterm.enable = true;
      ghostty.enable = true;
    };
    editor = {
      default = "nvim";
      visual = "zed-preview -w";
      neovim.enable = true;
      zed.enable = true;
    };

    homebrew = {
      enable = true;
      brewPrefix = brewPath;
      taps = [
        "homebrew/services"
      ];
      casks = [
        "betterdisplay"
        "figma"
        "ghostty"
        "google-chrome"
        "istat-menus"
        "jordanbaird-ice"
        "lunar"
        "signal"
        "utm"
        "crystalfetch"
        "calibre"
        "sony-ps-remote-play"
        "zen"
      ];
      masApps = {
        Keynote = 409183694;
        Kindle = 405399194;
        Numbers = 409203825;
        Pages = 409201541;
        Xcode = 497799835;
      };
    };
  };
  hm = {
    home = {
      packages = with pkgs; [
        slack
        tailscale
        my.tldx
        nur.repos.charmbracelet.crush
        iina
        chatgpt
        devenv
        podman
        inputs.beads.packages.${pkgs.system}.default
      ];
    };
  };
}
