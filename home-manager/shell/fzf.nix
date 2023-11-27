{ config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.fzf;

in {
  config = mkIf cfg.enable {
    programs.fzf = {
      enable = true;
      enableZshIntegration = config.modules.shell.zsh.enable;
      enableFishIntegration = config.modules.shell.fish.enable;
      defaultCommand = "fd --type f --hidden --follow --exclude .git";
    };
  };
}
