{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.fonts;

in
{
  options.modules.desktop.fonts = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    fonts = {
      packages = with pkgs; [
        nerd-fonts.monaspace
        nerd-fonts.fantasque-sans-mono
        open-sans
        input-fonts
        monaspace
      ];
    };
  };
}
