{
  config,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.psql;
in
{
  options.modules.dev.psql = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        file.".psqlrc".source = ../../../configs/psql/psqlrc;
      };
    };
  };
}
