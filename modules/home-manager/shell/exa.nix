{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.shell.exa = { enable = mkBoolOpt false; };
}
