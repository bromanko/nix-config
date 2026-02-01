{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.pi;
in
{
  options.modules.dev.pi = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        packages = [
          pkgs.llm-agents.pi
        ];
      };
    };
  };
}
