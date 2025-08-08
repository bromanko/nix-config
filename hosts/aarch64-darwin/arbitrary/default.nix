{ pkgs, lib, ... }:

let
  brewPath = "/opt/homebrew/bin";
in
with lib;
with lib.my;
{
  modules = {
    nix = {
      system.enable = true;
      dev.enable = true;
    };
    homeage = {
      enable = true;
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
      llm.enable = true;
    };
    desktop = {
      fonts.enable = true;
      dictionaries.enable = true;
      apps = {
        raycast.enable = true;
        "1Password".enable = true;
        vscode.enable = true;
        claude.enable = true;
      };
    };
    dev = {
      elixir.enable = true;
      idea.enable = true;
      psql.enable = true;
      docker.enable = true;
      nodejs.enable = true;
      aider-chat.enable = true;
      codex.enable = true;
    };
    term = {
      wezterm.enable = true;
      ghostty.enable = true;
    };
    editor = {
      default = "nvim";
      visual = "zed-preview -w";
      neovim.enable = true;
      emacs.enable = true;
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
        "docker"
        "figma"
        "ghostty"
        "google-chrome"
        "istat-menus"
        "jetbrains-toolbox"
        "jordanbaird-ice"
        "lunar"
        "signal"
        "utm"
        "crystalfetch"
        "arc"
        "calibre"
        "sony-ps-remote-play"
      ];
      masApps = {
        Keynote = 409183694;
        Kindle = 405399194;
        Numbers = 409203825;
        Pages = 409201541;
        Xcode = 497799835;
      };
    };
  };
  hm = {
    home = {
      packages = with pkgs; [
        slack
        tailscale
        my.claude-code
        my.tldx
        nur.repos.charmbracelet.crush
      ];
    };
  };
}
