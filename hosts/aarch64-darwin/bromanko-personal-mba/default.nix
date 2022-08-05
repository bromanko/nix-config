{ pkgs, config, lib, ... }:

with lib;
with lib.my; {
  modules = {
    shell = {
      commonPkgs.enable = true;
      openssh.enable = true;
      zsh = {
        enable = true;
        extraPaths = [ "$HOME/.emacs.d/bin" ];
      };
      bat.enable = true;
      git.enable = true;
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
        espanso.enable = true;
        vimari.enable = true;
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
    term = { kitty.enable = true; };
    editor = {
      neovim.enable = true;
      emacs.enable = true;
    };

    homebrew = {
      enable = true;
      brewPrefix = "/opt/homebrew/bin";
      taps = [
        "homebrew/cask"
        "homebrew/cask-versions"
        "homebrew/core"
        "homebrew/services"
        "federico-terzi/espanso"
      ];
      casks = [
        "1password"
        "bartender"
        "docker"
        "dropbox"
        "firefox"
        "google-chrome"
        "istat-menus"
        "jetbrains-toolbox"
        "lunar"
        "raycast"
        "signal"
        "spotify"
        "vmware-fusion"
        "notion"
      ];
      brews = [ "espanso" ];
      masApps = {
        Fantastical = 975937182;
        Keynote = 409183694;
        Kindle = 405399194;
        NextDNS = 1464122853;
        Numbers = 409203825;
        Pages = 409201541;
        Slack = 803453959;
        Tailscale = 1475387142;
        Xcode = 497799835;
      };
    };
  };
  services.nix-daemon.enable = true;
}
