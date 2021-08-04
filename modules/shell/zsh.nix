{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let
  isDarwin = pkgs.hostPlatform.isDarwin;
  isNotDarwin = !isDarwin;

  cfg = config.modules.shell.zsh;

  shellAliases = with pkgs; {
    ".." = "cd ..";
    "..." = "cd ../..";
    "reload!" = ". ~/.zshrc";
    S = "sudo";
    e = "$EDITOR";

    initgo = ''
      bash -c "$(curl -sS https://raw.githubusercontent.com/bromanko/dot-slash-go/master/install)"'';
  };

  commonCfg = {
    home-manager.users."${config.user.name}" = {
      home.sessionVariables = {
        SHELL = "${pkgs.zsh}/bin/zsh";

        # zsh-vim-mode
        MODE_CURSOR_VIINS = "#ffffff steady bar";
        MODE_CURSOR_VICMD = "#ffffff steady block";
      };

      programs.zsh = {
        enable = true;

        enableAutosuggestions = true;
        enableCompletion = true;
        history.extended = true;

        shellAliases = shellAliases;

        plugins = [
          {
            name = "zsh-bromanko-functions";
            src = ../../configs/zsh/plugins/zsh-bromanko-functions;
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
          {
            name = "zsh-fast-syntax-highlighting";
            file = "fast-syntax-highlighting.plugin.zsh";
            src = pkgs.fetchFromGitHub {
              owner = "zdharma";
              repo = "fast-syntax-highlighting";
              rev = "v1.55";
              sha256 = "019hda2pj8lf7px4h1z07b9l6icxx4b2a072jw36lz9bh6jahp32";
            };
          }
        ];
      };
      home.packages = [ pkgs.zsh-fast-syntax-highlighting ];
    };
  };

  darwinCfg = {
    programs.zsh.enable = true;
    environment.shells = [ pkgs.zsh ];
    environment.loginShell = pkgs.zsh;

    # Completion for system packages
    environment.pathsToLink = [ "/share/zsh" ];
  };

  nixosCfg = { };
in {
  options.modules.shell.zsh = with types; { enable = mkBoolOpt false; };

  config = mkIf cfg.enable (mkMerge [
    commonCfg
    (mkIf isDarwin darwinCfg)
    (mkIf isNotDarwin nixosCfg)
  ]);
}
