{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.dev.elixir = with types; { enable = mkBoolOpt false; };
}
