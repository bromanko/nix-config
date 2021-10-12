{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.shell.commonPkgs = { enable = mkBoolOpt false; };
}
