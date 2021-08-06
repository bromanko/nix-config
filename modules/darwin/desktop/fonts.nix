{ config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.fonts;

in {
  options.modules.desktop.fonts = with types; { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    fonts = {
      enableFontDir = true;
      fonts = with pkgs; [ my.fantasque-sans-mono-nerd-font ];
    };
  };
}
