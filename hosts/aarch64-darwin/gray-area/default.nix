{ pkgs, lib, ... }:

let
  brewPath = "/opt/homebrew/bin";
in
with lib;
with lib.my;
{
  modules = {
    # homeage = {
    #   enable = true;
    #   file = {
    #     "nix.config" = {
    #       source = ../../../configs/nix/nix.conf.age;
    #       symlinks = [ "$HOME/.config/nix/nix.conf" ];
    #     };
    #   };
    # };
    shell = {
      commonPkgs.enable = true;
      ssh.enable = true;
      openssh.enable = true;
      fish = {
        enable = true;
        extraPaths = [
          "$HOME/bin"
          brewPath
        ];
      };
      bat.enable = true;
      git.enable = true;
      jujutsu.enable = true;
      starship.enable = true;
      fzf.enable = true;
      direnv.enable = true;
      exa.enable = true;
      fd.enable = true;
    };
    desktop = {
      fonts.enable = true;
      apps = {
        raycast.enable = true;
        "1Password".enable = true;
      };
    };
    dev = {
      docker.enable = true;
      nix.enable = true;
    };
    term = {
      ghostty.enable = true;
    };
    editor = {
      default = "nvim";
      visual = "zed-preview -w";
      neovim.enable = true;
      zed.enable = true;
    };

    homebrew = {
      enable = true;
      brewPrefix = brewPath;
      taps = [
        "homebrew/services"
      ];
      casks = [
        "betterdisplay"
        "ghostty"
        "istat-menus"
        "jordanbaird-ice"
        "arc"
      ];
      masApps = {
        Xcode = 497799835;
        Tailscale = 1475387142;
      };
    };
  };
  services.nix-daemon.enable = true;
}
