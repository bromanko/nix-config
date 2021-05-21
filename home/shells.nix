{ config, pkgs, lib, ... }:

{
  home.sessionVariables = {
    EDITOR = "vim";

    # zsh-vim-mode
    MODE_CURSOR_VIINS = "#ffffff steady bar";
    MODE_CURSOR_VICMD = "#ffffff steady block";
  };

  programs.zsh.shellAliases = with pkgs; {
    ".." = "cd ..";
    "..." = "cd ../..";
    "reload!" = ". ~/.zshrc";
    S = "sudo";
    e = "$EDITOR";

    cat = "${bat}/bin/bat";
    "cat!" = "command cat";
    find = "${fd}/bin/fd";

    ll = "ls -l --time-style long-iso --icons";
    l = "ll -a";
    ls = "${exa}/bin/exa";

    g = "git";
    ga = "git add";
    gb = "git branch";
    gc = "git commit";
    gcm = "git checkout main";
    gco = "git checkout";
    gcp = "git cherry-pick";
    gd = "git diff";
    ggpush = "git push origin $(current_branch)";
    gl = "git pull --prune";
    gp = "git push origin HEAD";
    gs = "git status -sb";

    iex = ''iex --erl "-kernal shell_history enabled"'';

    dc = "docker-compose";
    initgo = ''
      bash -c "$(curl -sS https://raw.githubusercontent.com/bromanko/dot-slash-go/master/install)"'';
  };

  programs.zsh.plugins = [
    {
      name = "zsh-bromanko-functions";
      src = ./programs/zsh/plugins/zsh-bromanko-functions;
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

  programs.zsh.enable = true;
  programs.zsh.enableAutosuggestions = true;
  programs.zsh.enableCompletion = true;
  programs.zsh.history.extended = true;

  programs.starship.enable = true;
  programs.starship.enableZshIntegration = true;
  programs.starship.settings = {
    # See docs at https://starship.rs/config/
    #
    # Symbols are configures in Flake
    gcloud.disabled = true;
  };

  programs.zsh.initExtra = "";
}
