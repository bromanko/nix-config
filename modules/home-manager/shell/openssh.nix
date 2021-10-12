{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.shell.openssh = { enable = mkBoolOpt false; };
}
