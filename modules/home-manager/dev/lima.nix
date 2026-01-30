{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.lima;
in
{
  options.modules.dev.lima = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home.packages = with pkgs; [
        lima
        my.lima-tmux-shell
      ];

      home.file.".lima/_config/lima-dev.yaml" = {
        source = ../../../configs/lima/dev.yaml;
      };
    };
  };
}
