{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev.idea;
in {
  config = mkIf cfg.enable {
    home = { file.".ideavimrc".source = ../../configs/idea/ideavimrc; };
  };
}
