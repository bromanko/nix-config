{ config, lib, pkgs, ... }:

{
  fonts.enableFontDir = true;
  fonts.fonts = with pkgs; [ my.fantasque-sans-mono-nerd-font ];
}
