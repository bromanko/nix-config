{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.desktop.apps.zed;
in {
  options.modules.desktop.apps.zed = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable { homebrew = { casks = [ "zed@preview" ]; }; };
}
