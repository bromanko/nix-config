{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.dev.dotnet = with types; { enable = mkBoolOpt false; };
}
