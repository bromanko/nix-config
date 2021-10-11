{ config, lib, pkgs, ... }:

with lib;
let cfg = config.modules.editors;
in {
  config =
    mkIf (cfg.default != null) { home.sessionVariables.EDITOR = cfg.default; };
}
