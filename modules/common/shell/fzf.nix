{ config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.fzf;

in {
  options.modules.shell.fzf = with types; { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}".programs.fzf = {
      enable = true;
      enableZshIntegration = true;
      defaultCommand = "fd --type f --hidden --follow --exclude .git";
    };
  };
}
