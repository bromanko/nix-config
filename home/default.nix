{ config, pkgs, lib, ... }:

{
  imports = [ ./shells.nix ];

  programs.bat = {
    enable = true;
    config = { theme = "Monokai Extended"; };
  };

  programs.direnv = {
    enable = true;
    enableNixDirenvIntegration = true;
  };

  home.packages = with pkgs;
    [
      aspell # For Emacs
      bat
      bottom
      coreutils # For Emacs
      curl
      delta
      direnv
      exa
      fd
      fontconfig # For Emacs
      fzf
      gh
      git
      gnupg
      httpie
      imagemagick
      jq
      lorri
      neovim
      nixfmt
      peco
      python3
      ripgrep
      shellcheck
      shfmt
      tldr
      tmux
      tree
      yq
    ] ++ lib.optionals stdenv.isDarwin [ m-cli ];

  # This value determines the Home Manager release that your configuration is compatible with. This
  # helps avoid breakage when a new Home Manager release introduces backwards incompatible changes.
  #
  # You can update Home Manager without changing this value. See the Home Manager release notes for
  # a list of state version changes in each release.
  home.stateVersion = "21.03";
}