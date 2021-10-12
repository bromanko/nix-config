{ config, pkgs, lib, ... }:

with lib;
with lib.my; {
  options.modules.shell.direnv = with types; { enable = mkBoolOpt false; };
}
