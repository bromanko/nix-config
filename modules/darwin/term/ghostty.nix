{ lib, config, ... }:

with lib;
with lib.my;
let
  cfg = config.modules.term.ghostty;
in
{
  config = mkIf cfg.enable {
    modules = mkIf config.modules.homebrew.enable {
      homebrew = {
        casks = [ "ghostty" ];
      };
    };
  };
}
