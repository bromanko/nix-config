{
  config,
  pkgs,
  lib,
  inputs,
  ...
}:

let
  brewPrefix = "/opt/homebrew";
  brewPath = "${brewPrefix}/bin";

  github1PasswordPublicKey = "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzLxgUGkWXC/Hkvuxv4rsJfFYrYq1S16DouIXRXD2Ia";
  github1PasswordIdentityFile = "~/.ssh/github-1password.pub";
  onePasswordSshAgent = ''"${config.modules.shell."1password".sshSocketPath}"'';

  github1PasswordIdentity = {
    identityFile = [ github1PasswordIdentityFile ];
    identityAgent = [ onePasswordSshAgent ];
    identitiesOnly = true;
  };

  grayAreaSsh = pkgs.writeShellScriptBin "gray-area" ''
    set -euo pipefail

    exec ${pkgs.openssh}/bin/ssh gray-area "$@"
  '';

  grayAreaSshAttach = pkgs.writeShellScriptBin "gray-area-attach" ''
    set -euo pipefail

    escaped_args=()
    for arg in "$@"; do
      printf -v escaped_arg "%q" "$arg"
      escaped_args+=("$escaped_arg")
    done

    attach_command="et-attach"
    if (( ''${#escaped_args[@]} > 0 )); then
      attach_command+=" ''${escaped_args[*]}"
    fi

    exec ${pkgs.openssh}/bin/ssh -t gray-area "$attach_command"
  '';
in
with lib;
with lib.my;
{
  # Only allow SSH via 1Password key
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzLxgUGkWXC/Hkvuxv4rsJfFYrYq1S16DouIXRXD2Ia 1Password"
  ];

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
      ssh = {
        enable = true;
        envForwarding = {
          enable = true;
          hosts = [ "gray-area" ];
        };
      };
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
        macwhisper.enable = true;
        multitouch.enable = true;
        screencast = {
          enable = true;
          keycastr.enable = true;
          loom.enable = true;
        };
        aerospace = {
          enable = true;
          jankyBorders.enable = false;
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
              "if".app-id = "com.openai.codex";
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
      elixir.enable = true;
      idea.enable = true;
      psql.enable = true;
      docker.enable = true;
      nodejs.enable = true;
      codex.enable = true;
      claude-code.enable = true;
      pi.enable = true;
      lima.enable = true;
      "secret-proxy" = {
        enable = true;
        namespaces = [ "michael" ];
        contextLens.enable = true;
      };
      context-lens.enable = true;
    };
    term = {
      ghostty.enable = true;
      tmux.enable = true;
    };
    editor = {
      default = "nvim";
      visual = "zed-preview -w";
      neovim.enable = true;
      zed.enable = true;
    };

    openssh = {
      enable = true;
      tailscaleOnly = true;
      envForwarding.enable = true;
    };

    homebrew = {
      enable = true;
      prefix = brewPrefix;
      taps = [ ];
      casks = [
        "anki"
        "bartender"
        "betterdisplay"
        "figma"
        "google-chrome"
        "hazeover"
        "homerow"
        "iina"
        "istat-menus"
        "linear"
        "lunar"
        "signal"
        "utm"
        "crystalfetch"
        "calibre"
        "obsidian"
        "sony-ps-remote-play"
        "tailscale-app"
        "copilot-money"
        "zen"
      ];
      masApps = {
        Keynote = 409183694;
        Numbers = 409203825;
        Pages = 409201541;
        Xcode = 497799835;
      };
    };
  };
  hm = {
    home = {
      packages =
        (with pkgs; [
          slack
          tailscale
          my.tldx
          my.sprite
          my.ticket
          my.chrome-devtools-mcp
          my.codex-app
          devenv
          podman
        ])
        ++ [
          grayAreaSsh
          grayAreaSshAttach
        ];

      file.".ssh/github-1password.pub".text = "${github1PasswordPublicKey}\n";
    };

    programs.ssh.matchBlocks = {
      github = github1PasswordIdentity // {
        host = "github.com";
        hostname = "github.com";
        user = "git";
      };

      hetzner = github1PasswordIdentity // {
        host = "hetzner sleeper-service";
      };
    };
  };
}
