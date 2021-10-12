{ config, pkgs, lib, ... }:

with lib;
with lib.my; {
  options.modules.shell.bat = with types; { enable = mkBoolOpt false; };
}
