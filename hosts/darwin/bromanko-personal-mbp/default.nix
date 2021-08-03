{ pkgs, config, lib, ... }:

with lib;
with lib.my; {
  modules = {
    shell = {
      bat.enable = true;
      zsh.enable = true;
      starship.enable = true;
      fzf.enable = true;
      direnv.enable = true;
    };
    desktop = {
      apps = {
        raycast.enable = true;
        espanso.enable = true;
      };
    };
    dev = {
      elixir.enable = true;
      idea.enable = true;
      psql.enable = true;
    };
    term = { kitty.enable = true; };
    editor = { neovim.enable = true; };

    darwin.homebrew = {
      enable = true;
      taps = [
        "homebrew/cask"
        "homebrew/cask-versions"
        "homebrew/core"
        "homebrew/services"
        "frederico-terzi/espanso"
      ];
      casks = [
        "docker"
        "dropbox"
        "firefox"
        "google-chrome"
        "istat-menus"
        "jetbrains-toolbox"
        "raycast"
        "signal"
        "spotify"
        "vmware-fusion"
      ];
      brews = [ "espanso" ];
      masApps = {
        "1Password" = 1333542190;
        Amphetamine = 937984704;
        Fantastical = 975937182;
        Keynote = 409183694;
        Kindle = 405399194;
        NextDNS = 1464122853;
        Numbers = 409203825;
        Pages = 409201541;
        Slack = 803453959;
        Tailscale = 1475387142;
        "Unsplash Wallpapers" = 1284863847;
        Xcode = 497799835;
      };
    };
  };
}
