{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.apps.vscode;
in {
  options.modules.desktop.apps.vscode = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable { hm = { programs.vscode = { enable = true; }; }; };
}
