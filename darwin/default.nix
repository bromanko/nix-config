{ pkgs, lib, ... }:

{
  imports = [ ./bootstrap.nix ./defaults.nix ];

  fonts.enableFontDir = true;
  fonts.fonts = [ pkgs.recursive ];

  system.keyboard.enableKeyMapping = true;
  system.keyboard.remapCapsLockToEscape = true;

  # Lorri daemon
  # https://github.com/target/lorri
  # Used in conjuction with Direnv which is installed in `../home/default.nix`.
  services.lorri.enable = true;

  # Set default shell
  # users.users."${username}" = {
  # inherit home;
  # shell = pkgs.zsh;
  # };
}
