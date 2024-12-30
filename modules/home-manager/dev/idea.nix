{ config, lib, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.dev.idea;
in
{
  options.modules.dev.idea = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        file.".ideavimrc".source = ../../../configs/idea/ideavimrc;
      };
    };
  };
}
