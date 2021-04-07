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
  ];

  homebrew.casks = [
    "alfred"
    "docker"
    "firefox"
    "istat-menus"
    "jetbrains-toolbox"
    "rectangle"
    "signal"
    "spotify"
  ];

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

