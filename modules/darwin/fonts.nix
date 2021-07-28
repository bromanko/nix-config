{ config, lib, pkgs, ... }:

with lib.my; {
  fonts.enableFontDir = true;
  fonts.fonts = [ my.fantasque-sans-mono-nerd-font ];
}
