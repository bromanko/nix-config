{ lib, ... }:

with lib;
with lib.my; {
  options.modules.editor = {
    default = mkOpt types.str "vim";
    visual = mkOpt types.str "";
  };
}
