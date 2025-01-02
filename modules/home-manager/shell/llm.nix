{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.llm;
in
{
  options.modules.shell.llm = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        packages = with pkgs; [
          llm
        ];
      };
    };
  };
}
