{
  config,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.codex;
in
{
  options.modules.dev.codex = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      programs.codex = {
        enable = true;
      };
    };
  };
}
