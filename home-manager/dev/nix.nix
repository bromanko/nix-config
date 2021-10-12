{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev.nix;
in {
  config = mkIf cfg.enable { home = { packages = with pkgs; [ nixfmt ]; }; };
}
