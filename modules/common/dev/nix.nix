{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev.nix;
in {
  options.modules.dev.nix = with types; { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}" = {
      home = { packages = with pkgs; [ nixfmt ]; };
    };
  };
}
