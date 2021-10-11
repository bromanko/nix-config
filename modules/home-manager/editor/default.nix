{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.editors = { default = mkOpt types.str "vim"; };
}
