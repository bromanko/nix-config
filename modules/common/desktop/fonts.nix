{ config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.fonts;

in {
  options.modules.desktop.fonts = with types; { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    fonts = {
      fonts = with pkgs; [
        (nerdfonts.override { fonts = [ "FantasqueSansMono" ]; })
        open-sans
      ];
    };
  };
}
