{ lib, config, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.editor;
in
{
  options.modules.editor = {
    default = mkOpt types.str "vim";
    visual = mkOpt types.str "";
  };

  config = {
    hm = {
      home = {
        sessionVariables = {
          EDITOR = mkIf (cfg.default != null) cfg.default;
          VISUAL = mkIf (cfg.visual != null) cfg.visual;
        };
      };
    };
  };
}
