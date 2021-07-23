{ config, lib, pkgs, ... }:

{
  fonts.enableFontDir = true;
  fonts.fonts = [ pkgs.fantasque-sans-mono-nerd-font ];
}
