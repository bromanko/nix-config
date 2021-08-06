{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev.nodejs;
in {
  options.modules.dev.nodejs = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}" = {
      home.packages = [ pkgs.nodejs pkgs.nodePackages.prettier ];
    };
  };
}
