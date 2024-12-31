{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.openssh;
in
{
  options.modules.shell.openssh = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        packages = with pkgs; [ openssh ];
      };
    };
  };
}
