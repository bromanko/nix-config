{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.zen;
in
{
  options.modules.desktop.apps.zen = {
    enable = mkBoolOpt false;
  };

  config = mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isDarwin) {
    modules.homebrew.casks = [ "zen" ];
  };
}
