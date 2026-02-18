{
  config,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.screencast;
  casks = optionals cfg.cap.enable [ "cap" ] ++ optionals cfg.keycastr.enable [ "keycastr" ];
in
{
  options.modules.desktop.apps.screencast = {
    enable = mkBoolOpt false;

    cap.enable = mkBoolOpt true;
    keycastr.enable = mkBoolOpt true;
  };

  config = mkIf cfg.enable {
    modules.homebrew.casks = casks;
  };
}
