{
  config,
  lib,
  ...
}:

with lib;
with lib.my;

let
  cfg = config.modules.shell.fzf;

in
{
  options.modules.shell.fzf = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      programs.fzf = {
        enable = true;
        enableZshIntegration = config.modules.shell.zsh.enable;
        enableFishIntegration = config.modules.shell.fish.enable;
        defaultCommand = "fd --type f --hidden --follow --exclude .git";
      };
    };
  };
}
