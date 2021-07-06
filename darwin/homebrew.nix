{
  homebrew.enable = true;
  homebrew.autoUpdate = true;
  homebrew.cleanup = "zap";
  homebrew.global.brewfile = true;
  homebrew.global.noLock = true;

  homebrew.taps = [
    "homebrew/cask"
    "homebrew/cask-versions"
    "homebrew/core"
    "homebrew/services"
    "federico-terzi/espanso"
  ];

  homebrew.casks = [
    "alfred"
    "docker"
    "dropbox"
    "firefox"
    "google-chrome"
    "istat-menus"
    "jetbrains-toolbox"
    "rectangle"
    "raycast"
    "signal"
    "spotify"
  ];

  homebrew.brews = [ "espanso" ];

  homebrew.masApps = {
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
}

