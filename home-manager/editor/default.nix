{ config, lib, pkgs, ... }:

with lib;
let cfg = config.modules.editor;
in {
  config =
    mkIf (cfg.default != null) { home.sessionVariables.EDITOR = cfg.default; };
}
