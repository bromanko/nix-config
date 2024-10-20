{ config, lib, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.editor;
in
{
  config = {
    home = {
      sessionVariables = {
        EDITOR = mkIf (cfg.default != null) cfg.default;
        VISUAL = mkIf (cfg.visual != null) cfg.visual;
      };
    };
  };
}
