{ config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.direnv;

in {
  config = mkIf cfg.enable {
    programs.direnv = {
      enable = true;
      nix-direnv = { enable = true; };
    };
  };
}
