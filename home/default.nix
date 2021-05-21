{ config, pkgs, lib, ... }:

{
  imports = [ ./shells.nix ./neovim.nix ./emacs.nix ./kitty.nix ];

  programs.bat = {
    enable = true;
    config = { theme = "Monokai Extended"; };
  };

  programs.direnv = {
    enable = true;
    enableNixDirenvIntegration = true;
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
      exa
      fantasque-sans-mono-nerd-font
      fd
      fontconfig # For Emacs
      gh
      git
      gnupg
      httpie
      imagemagick
      jq
      nixfmt
      nodejs
      nodePackages.prettier
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

  home.file."Library/Preferences/espanso/default.yml".source =
    ../configs/espanso/default.yml;
  home.file."Library/Preferences/espanso/user" = {
    recursive = true;
    source = ../configs/espanso/user;
  };

  home.file.".iex.exs".source = ../configs/elixir/iex.exs;

  home.file.".psqlrc".source = ../configs/psql/psqlrc;

  home.activation = lib.mkIf (pkgs.stdenv.hostPlatform.isDarwin) {
    copyApplications = let
      apps = pkgs.buildEnv {
        name = "home-manager-applications";
        paths = config.home.packages;
        pathsToLink = "/Applications";
      };
    in lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # Install MacOS applications to the user environment.
      HM_APPS="$HOME/Applications/Home Manager Apps"

      # Reset current state
      [ -e "$HM_APPS" ] && $DRY_RUN_CMD rm -r "$HM_APPS"
      $DRY_RUN_CMD mkdir -p "$HM_APPS"

      # .app dirs need to be actual directories for Finder to detect them as Apps.
      # The files inside them can be symlinks though.
      $DRY_RUN_CMD cp --recursive --symbolic-link --no-preserve=mode -H ${apps}/Applications/* "$HM_APPS"
      # Modes need to be stripped because otherwise the dirs wouldn't have +w,
      # preventing us from deleting them again
      # In the env of Apps we build, the .apps are symlinks. We pass all of them as
      # arguments to cp and make it dereference those using -H
    '';
  };

  # This value determines the Home Manager release that your configuration is compatible with. This
  # helps avoid breakage when a new Home Manager release introduces backwards incompatible changes.
  #
  # You can update Home Manager without changing this value. See the Home Manager release notes for
  # a list of state version changes in each release.
  home.stateVersion = "21.03";
}
