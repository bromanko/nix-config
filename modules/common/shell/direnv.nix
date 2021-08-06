{ config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.direnv;

in {
  options.modules.shell.direnv = with types; { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}".programs.direnv = {
      enable = true;
      nix-direnv.enable = true;
    };
  };
}
