{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.dev.nodejs = { enable = mkBoolOpt false; };
}
