{ pkgs, ... }:

let
  brewPrefix = "/opt/homebrew";
  brewPath = "${brewPrefix}/bin";
in
{
  # Only allow SSH via the Gray Area key in the 1Password SSH agent.
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIDhMuyTBj/2cYLaBjtdi5nZHwm281C51LogGRhG8A7mt Gray Area"
  ];

  # Keep this machine reachable over Tailscale for SSH and Eternal Terminal.
  power.sleep.computer = "never";

  modules = {
    nix = {
      system.enable = "determinate";
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
        dealmail.enable = true;
      };
    };
    dev = {
      docker.enable = true;
      claude-code.enable = true;
      pi.enable = true;
    };
    term = {
      ghostty.enable = true;
      tmux.enable = true;
      eternal-terminal.server.enable = true;
    };
    editor = {
      default = "nvim";
      visual = "zed-preview -w";
      neovim.enable = true;
      zed.enable = true;
    };
    openssh.enable = true;

    homebrew = {
      enable = true;
      prefix = brewPrefix;
      taps = [
        "homebrew/services"
      ];
      casks = [
        "betterdisplay"
        "google-chrome"
        "istat-menus"
        "jordanbaird-ice"
        "zen"
      ];
      masApps = {
        Xcode = 497799835;
      };
    };
  };
  hm = {
    home = {
      packages = with pkgs; [
        tailscale
        devenv
      ];
    };
  };
}
