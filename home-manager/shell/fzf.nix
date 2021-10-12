{ config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.fzf;

in {
  config = mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd --type f --hidden --follow --exclude .git";
    };
  };
}
