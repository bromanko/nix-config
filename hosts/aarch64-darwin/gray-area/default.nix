{ pkgs, lib, ... }:

let
  brewPath = "/opt/homebrew/bin";
in
{
  authorizedKeys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2vkvKlul2zm/Qx7V0NmmwGDJcFY46tf9asOVONkcCK 1Password"
  ];
  modules = {
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
    openssh.enable = true;

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
        Tailscale = 1470499037;
        Xcode = 497799835;
      };
    };
  };
  services.nix-daemon.enable = true;
}
