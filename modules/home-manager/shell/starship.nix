{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options = {
    modules.shell.starship = with types; { enable = mkBoolOpt false; };
  };
}
