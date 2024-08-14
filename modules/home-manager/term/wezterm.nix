{ config, lib, ... }:

with lib;
with lib.my;

let cfg = config.modules.term.wezterm;
in {
  options.modules.term.wezterm = with types; { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    hm = {
      programs.wezterm = {
        enable = true;
        enableZshIntegration = config.modules.shell.zsh.enable;
        extraConfig = ''
          return {
            font = wezterm.font("MonaspiceAr Nerd Font Mono Light")
            font_size = 14;
          }
        '';
      };
    };
  };
}
