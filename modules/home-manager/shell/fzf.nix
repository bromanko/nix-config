{ config, pkgs, lib, ... }:

with lib;
with lib.my; {
  options.modules.shell.fzf = with types; { enable = mkBoolOpt false; };
}
