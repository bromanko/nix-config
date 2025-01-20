{ lib, config, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.openssh;
in
{
  options.modules.openssh = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    services.openssh.enable = true;
  };
}
