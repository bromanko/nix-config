{ config, pkgs, lib, ... }:

{

  home.packages = with pkgs;
    [
      (aspellWithDicts (dicts: with dicts; [ en en-computers en-science ]))
      bat
      bottom
      cmake
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
      nixfmt
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

  home.file.".iex.exs".source = ../configs/elixir/iex.exs;

  home.file.".psqlrc".source = ../configs/psql/psqlrc;

}
