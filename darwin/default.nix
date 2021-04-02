{ pkgs, lib, ... }:

{
  imports = [ ./bootstrap.nix ./defaults.nix ];

  environment.systemPackages = with pkgs; [
    aspell # For Emacs
    bat
    bottom
    coreutils # For Emacs
    delta
    direnv
    fd
    fontconfig # For Emacs
    fzf
    gh
    git
    gnupg
    google-cloud-sdk
    kubernetes-helm
    httpie
    imagemagick
    jq
    kind
    kubectl
    kubectx
    kustomize
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
    zsh
    zsh-syntax-highlighting
  ];

  fonts.enableFontDir = true;
  fonts.fonts = [ pkgs.recursive ];

  system.keyboard.remapCapsLockToEscape = true;

  # Lorri daemon
  # https://github.com/target/lorri
  # Used in conjuction with Direnv which is installed in `../home/default.nix`.
  services.lorri.enable = true;

  # Set default snell
  # users.users."${username}" = {
  # inherit home;
  # shell = pkgs.zsh;
  # };
}
