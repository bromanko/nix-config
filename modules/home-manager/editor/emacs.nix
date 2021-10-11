{ config, pkgs, lib, ... }:

with lib;
with lib.my; {
  options.modules.editor.emacs = with types; { enable = mkBoolOpt false; };
}
