{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.shell.git = { enable = mkBoolOpt false; };
}
