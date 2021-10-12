{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev.psql;
in {
  config = mkIf cfg.enable {
    home = { file.".psqlrc".source = ../../configs/psql/psqlrc; };
  };
}
