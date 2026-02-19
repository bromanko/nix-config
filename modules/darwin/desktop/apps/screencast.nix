{
  config,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.screencast;
  casks =
    optionals cfg.cap.enable [ "cap" ]
    ++ optionals cfg.keycastr.enable [ "keycastr" ]
    ++ optionals cfg.loom.enable [ "loom" ];
in
{
  options.modules.desktop.apps.screencast = {
    enable = mkBoolOpt false;

    cap.enable = mkBoolOpt true;
    keycastr.enable = mkBoolOpt true;
    loom.enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    modules.homebrew.casks = casks;
  };
}
