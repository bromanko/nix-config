{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.editor = { default = mkOpt types.str "vim"; };
}
