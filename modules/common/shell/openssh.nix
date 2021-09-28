{ config, options, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.openssh;
in {
  options.modules.shell.openssh = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}".home = {
      packages = with pkgs; [ openssh ];
    };
  };
}
