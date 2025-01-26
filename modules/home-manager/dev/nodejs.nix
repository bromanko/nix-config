{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.nodejs;
in
{
  options.modules.dev.nodejs = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home.packages = [
        pkgs.nodejs
        pkgs.nodePackages.prettier
      ];
    };
  };
}
