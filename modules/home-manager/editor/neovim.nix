{ config, pkgs, lib, ... }:

with lib;
with lib.my; {
  options.modules.editor.neovim = with types; { enable = mkBoolOpt false; };
}
