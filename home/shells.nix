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
    cat = "${bat}/bin/bat";
    "cat!" = "command cat";
    find = "${fd}/bin/fd";
    initgo = ''
      bash -c "$(curl -sS https://raw.githubusercontent.com/bromanko/dot-slash-go/master/install)"'';
    la = "ll -a";
    ll = "ls -l --time-style long-iso --icons";
    l = "ll";
    ls = "${exa}/bin/exa";
    "reload!" = ". ~/.zshrc";
    vim = "${neovim}/bin/nvim";
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
  };

  programs.zsh.enable = true;
  # programs.zsh.enableBashCompletion = true;
  # programs.zsh.enableFzfCompletion = true;
  # programs.zsh.enableFzfGit = true;
  # programs.zsh.enableFzfHistory = true;
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

  programs.zsh.initExtra = ''
    source ${pkgs.zsh-fast-syntax-highlighting}/share/zsh/site-functions/fast-syntax-highlighting.plugin.zsh
    source ${pkgs.zsh-vim-mode}/share/zsh/plugins/zsh-vim-mode/zsh-vim-mode.plugin.zsh
  '';
}
