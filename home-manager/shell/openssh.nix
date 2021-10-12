{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.openssh;
in {
  config = mkIf cfg.enable { home = { packages = with pkgs; [ openssh ]; }; };
}
