{ pkgs, lib, ... }:

let
  brewPath = "/opt/homebrew/bin";
in
with lib;
with lib.my;
{
  modules = {
    homeage = {
      enable = true;
      file = {
        "nix.config" = {
          source = ../../../configs/nix/nix.conf.age;
          symlinks = [ "$HOME/.config/nix/nix.conf" ];
        };
      };
    };
    shell = {
      commonPkgs.enable = true;
      ssh.enable = true;
      openssh.enable = true;
      fish = {
        enable = true;
        extraPaths = [
          "$HOME/bin"
          "$HOME/.config/emacs/bin"
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
      dictionaries.enable = true;
      apps = {
        raycast.enable = true;
        vimari.enable = true;
        "1Password".enable = true;
        vscode.enable = true;
      };
    };
    dev = {
      elixir.enable = true;
      idea.enable = true;
      dotnet.enable = true;
      psql.enable = true;
      docker.enable = true;
      nix.enable = true;
      nodejs.enable = true;
    };
    term = {
      kitty = {
        enable = true;
        fontSize = 13;
      };
      wezterm.enable = true;
    };
    editor = {
      default = "nvim";
      visual = "zed-preview";
      neovim.enable = true;
      emacs.enable = true;
      zed.enable = true;
      helix.enable = true;
    };

    homebrew = {
      enable = true;
      brewPrefix = brewPath;
      taps = [
        "homebrew/cask-versions"
        "homebrew/services"
      ];
      casks = [
        "betterdisplay"
        "dash"
        "docker"
        "figma"
        "google-chrome"
        "istat-menus"
        "jetbrains-toolbox"
        "jordanbaird-ice"
        "lunar"
        "signal"
        "spotify"
        "orion"
        "utm"
        "crystalfetch"
        "arc"
        "calibre"
      ];
      masApps = {
        Keynote = 409183694;
        Kindle = 405399194;
        Numbers = 409203825;
        Pages = 409201541;
        Tailscale = 1475387142;
        Xcode = 497799835;
        Wireguard = 1451685025;
      };
    };
  };
  hm = {
    home = {
      packages = with pkgs; [
        slack
        tailscale
        aldente
      ];
    };
  };
  services.nix-daemon.enable = true;
}
