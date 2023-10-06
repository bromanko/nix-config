{ pkgs, config, lib, ... }:

let brewPath = "/opt/homebrew/bin";
in with lib;
with lib.my; {
  modules = {
    shell = {
      commonPkgs.enable = true;
      openssh.enable = true;
      zsh = {
        enable = true;
        extraPaths = [ "$HOME/.emacs.d/bin" brewPath ];
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
      dictionaries.enable = true;
      apps = {
        raycast.enable = true;
        espanso.enable = true;
        vimari.enable = true;
        "1Password".enable = true;
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
      brewPrefix = brewPath;
      taps = [
        "homebrew/cask"
        "homebrew/cask-versions"
        "homebrew/core"
        "homebrew/services"
        "federico-terzi/espanso"
      ];
      casks = [
        "bartender"
        "betterdisplay"
        "docker"
        "dropbox"
        "firefox"
        "figma"
        "google-chrome"
        "istat-menus"
        "jetbrains-toolbox"
        "lunar"
        "signal"
        "spotify"
        "notion"
        "orion"
        "kindavim"
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
  hm = { home = { packages = with pkgs; [ slack tailscale ]; }; };
  services.nix-daemon.enable = true;
}
