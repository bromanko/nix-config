{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  modules = { desktop.apps.espanso.enable = true; };
}
