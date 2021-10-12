{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.dev.idea = with types; { enable = mkBoolOpt false; };
}
