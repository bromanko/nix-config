{ pkgs, lib, ... }:

{
  imports = [ ./bootstrap.nix ./defaults.nix ./homebrew.nix ];

  # https://github.com/nix-community/home-manager/issues/423
  environment.variables = {
    TERMINFO_DIRS = "${pkgs.kitty.terminfo.outPath}/share/terminfo";
  };

  fonts.enableFontDir = true;
  fonts.fonts = [ pkgs.fantasque-sans-mono-nerd-font ];

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;

  # Lorri daemon
  # https://github.com/target/lorri
  # Used in conjuction with Direnv which is installed in `../home/default.nix`.
  services.lorri.enable = true;

  services.emacs = { enable = true; };
}
