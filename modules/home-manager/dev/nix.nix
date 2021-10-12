{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.dev.nix = with types; { enable = mkBoolOpt false; };
}
