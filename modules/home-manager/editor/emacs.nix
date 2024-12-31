{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.editor.emacs;
in
{
  options.modules.editor.emacs = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        file.".doom.d".source = ../../../configs/emacs/doom.d;

        packages = with pkgs; [
          (aspellWithDicts (
            dicts: with dicts; [
              en
              en-computers
              en-science
            ]
          ))
          cmake
          html-tidy
          coreutils
          fontconfig
          imagemagick
          sqlite
        ];
      };
    };
  };
}
