{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.toad;
in
{
  options.modules.dev.toad = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        packages = [
          pkgs.my.toad
          pkgs.claude-code-acp
        ];
      };
    };
  };
}
