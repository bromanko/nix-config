{ config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.bat;

in {
  options.modules.shell.bat = with types; { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}".programs.bat = {
      enable = true;
      config = { theme = "Monokai Extended"; };
    };
  };
}
