{ config, pkgs, lib, ... }:

{
  imports = [ ./shells.nix ./neovim.nix ./emacs.nix ./kitty.nix ./darwin.nix ];

  programs.bat = {
    enable = true;
    config = { theme = "Monokai Extended"; };
  };

  programs.direnv = {
    enable = true;
    nix-direnv.enable = true;
  };

  programs.fzf = {
    enable = true;
    enableZshIntegration = true;
    defaultCommand = "fd --type f --hidden --follow --exclude .git";
  };

  home.packages = with pkgs;
    [
      (aspellWithDicts (dicts: with dicts; [ en en-computers en-science ]))
      bat
      bottom
      coreutils # For Emacs
      curl
      delta
      duf
      du-dust
      elixir_ls
      exa
      fantasque-sans-mono-nerd-font
      fd
      fontconfig # For Emacs
      gh
      git
      gnupg
      httpie
      html-tidy
      imagemagick
      jq
      nixpkgs-fmt
      nodejs
      nodePackages.prettier
      openssh
      peco
      python3
      ripgrep
      shellcheck
      shfmt
      tldr
      tmux
      tree
      yq
      zsh-fast-syntax-highlighting
    ] ++ lib.optionals stdenv.isDarwin [ m-cli ];

  home.file.".ideavimrc".source = ../configs/idea/ideavimrc;

  home.file.".vieb/viebrc".source = ../configs/vieb/viebrc;
  home.file.".vieb/colors/bigsur-dark.css".source =
    ../configs/vieb/bigsur-dark.css;

  home.file.".iex.exs".source = ../configs/elixir/iex.exs;

  home.file.".psqlrc".source = ../configs/psql/psqlrc;


  # This value determines the Home Manager release that your configuration is compatible with. This
  # helps avoid breakage when a new Home Manager release introduces backwards incompatible changes.
  #
  # You can update Home Manager without changing this value. See the Home Manager release notes for
  # a list of state version changes in each release.
  home.stateVersion = "21.03";
}
