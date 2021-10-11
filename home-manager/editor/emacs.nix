{ config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.editor.emacs;

in {
  config = mkIf cfg.enable {
    home.file.".doom.d".source = ../../configs/emacs/doom.d;

    home.packages = with pkgs; [
      (aspellWithDicts (dicts: with dicts; [ en en-computers en-science ]))
      cmake
      html-tidy
      coreutils
      fontconfig
      imagemagick
      sqlite
    ];
  };
}
