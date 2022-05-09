{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.desktop.apps.surfingkeys = { enable = mkBoolOpt false; };
}
