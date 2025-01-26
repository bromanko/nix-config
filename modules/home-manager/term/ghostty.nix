{ lib, config, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.term.ghostty;
in
{
  options.modules.term.ghostty = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home.file."Library/Application Support/com.mitchellh.ghostty/config" = {
        source = ../../../configs/ghostty/config;
      };
    };
  };
}
