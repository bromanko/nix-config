{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.zsh;
in {
  config = mkIf cfg.enable {
    home = {
      packages = with pkgs; [ zsh-history-substring-search ];

      sessionVariables = {
        SHELL = "${pkgs.zsh}/bin/zsh";
        PROJECTS = cfg.projectsPath;

        # zsh-vim-mode
        MODE_CURSOR_VIINS = "#ffffff steady bar";
        MODE_CURSOR_VICMD = "#ffffff steady block";
      };
    };

    programs.zsh = {
      enable = true;

      enableAutosuggestions = true;
      enableSyntaxHighlighting = true;
      enableCompletion = true;
      history.extended = true;

      shellAliases = {
        ".." = "cd ..";
        "..." = "cd ../..";
        "...." = "cd ../../../";
        "....." = "cd ../../../../";
        "reload!" = ". ~/.zshrc";
        S = "sudo";
        e = "$EDITOR";

        initgo = ''
          bash -c "$(curl -sS https://raw.githubusercontent.com/bromanko/dot-slash-go/master/install)"'';
      };

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
      ];

      initExtra = ''
        ${concatStrings (map (path: ''
          path+="${path}"
        '') cfg.extraPaths)}

        # zsh-history-substring-search
        source ${pkgs.zsh-history-substring-search}/share/zsh-history-substring-search/zsh-history-substring-search.zsh
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
        bindkey "$terminfo[kcuu1]" history-substring-search-up
        bindkey "$terminfo[kcud1]" history-substring-search-down
        bindkey '^ ' autosuggest-accept
        HISTORY_SUBSTRING_SEARCH_ENSURE_UNIQUE=1
        HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_FOUND="fg=blue,bold"
        HISTORY_SUBSTRING_SEARCH_HIGHLIGHT_NOT_FOUND="fg=red,bold"
        ZSH_AUTOSUGGEST_STRATEGY=( history )
      '';
    };
  };
}
