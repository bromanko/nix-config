{
  lib,
  ...
}:

with lib;
with lib.my;
{
  options.modules.editor.zed = {
    enable = mkBoolOpt false;
  };

}
