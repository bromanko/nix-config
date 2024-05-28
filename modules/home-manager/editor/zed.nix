{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.editor.zed;
in {
  options.modules.editor.zed = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable { homebrew = { casks = [ "zed@preview" ]; }; };
}
