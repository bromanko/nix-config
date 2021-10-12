{ config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.bat;

in {
  config = mkIf cfg.enable {
    programs.bat = {
      enable = true;
      config = { theme = "Monokai Extended"; };
    };

    programs.zsh.shellAliases = mkIf config.modules.shell.zsh.enable {
      cat = "${pkgs.bat}/bin/bat";
      "cat!" = "command cat";
    };
  };
}
