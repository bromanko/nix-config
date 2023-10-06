{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.shell.ssh = { enable = mkBoolOpt false; };
}
