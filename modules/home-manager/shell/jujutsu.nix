{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.jujutsu;
in {
  options.modules.shell.jujutsu = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    hm = {
      programs.jujutsu = { enable = true; };

      programs.git = { ignores = [ ".jj" ]; };
    };
  };
}
