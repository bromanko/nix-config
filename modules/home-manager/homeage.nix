{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.homeage = { enable = mkBoolOpt false; };
}
