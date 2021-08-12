{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.zsh;
in {
  options.modules.shell.zsh = with types; {
    enable = mkBoolOpt false;
    projectsPath =
      mkOpt' str "$HOME/Code" "Directory containing project files.";
  };

  config = {
    home-manager.users."${config.user.name}" = {
      home.sessionVariables = {
        SHELL = "${pkgs.zsh}/bin/zsh";
        PROJECTS = cfg.projectsPath;

        # zsh-vim-mode
        MODE_CURSOR_VIINS = "#ffffff steady bar";
        MODE_CURSOR_VICMD = "#ffffff steady block";
      };

      programs.zsh = {
        enable = true;

        enableAutosuggestions = true;
        enableCompletion = true;
        history.extended = true;

        shellAliases = with pkgs; {
          ".." = "cd ..";
          "..." = "cd ../..";
          "reload!" = ". ~/.zshrc";
          S = "sudo";
          e = "$EDITOR";

          initgo = ''
            bash -c "$(curl -sS https://raw.githubusercontent.com/bromanko/dot-slash-go/master/install)"'';
        };

        plugins = [
          {
            name = "zsh-bromanko-functions";
            src = ../../../configs/zsh/plugins/zsh-bromanko-functions;
          }
          {
            name = "zsh-vim-mode";
            src = pkgs.fetchFromGitHub {
              owner = "softmoth";
              repo = "zsh-vim-mode";
              rev = "1f9953b";
              sha256 = "a+6EWMRY1c1HQpNtJf5InCzU7/RphZjimLdXIXbO6cQ=";
            };
          }
        ];
      };
      home.packages =
        [ pkgs.zsh-fast-syntax-highlighting pkgs.zsh-history-substring-search ];
    };

    environment.shells = [ pkgs.zsh ];
  };
}