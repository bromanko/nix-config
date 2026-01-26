{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.claude-squad;
in
{
  options.modules.dev.claude-squad = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        packages = [
          pkgs.my.claude-squad
        ];
      };
    };
  };
}
