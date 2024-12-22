{
  config,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.editor.zed;
in
{
  options.modules.editor.zed = {
    enable = mkBoolOpt false;
  };

}
