{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.dev.psql = with types; { enable = mkBoolOpt false; };
}
