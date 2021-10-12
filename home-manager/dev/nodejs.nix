{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev.nodejs;
in {
  config = mkIf cfg.enable {
    home.packages = [ pkgs.nodejs pkgs.nodePackages.prettier ];
  };
}
