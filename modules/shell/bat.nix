{ config, options, lib, pkgs, ... }:


let cfg = config.modules.shell.bat;
in {
  config = mkIf cfg.enable
  programs.bat = {
    enable = true;
    config = { theme = "Monokai Extended"; };
  };
}
