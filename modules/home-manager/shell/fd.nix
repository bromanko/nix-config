{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.shell.fd = { enable = mkBoolOpt false; };
}
