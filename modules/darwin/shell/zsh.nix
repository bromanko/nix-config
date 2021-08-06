{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  config = { programs.zsh = { enable = true; }; };
}
