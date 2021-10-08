{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.desktop.apps.espanso = { enable = mkBoolOpt false; };
}
