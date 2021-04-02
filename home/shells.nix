{ config, pkgs, lib, ... }:

{
  programs.zsh.shellAliases = with pkgs; {
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
    gcloud.disabled = true;
  };
}
