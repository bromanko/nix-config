{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev.idea;
in {
  options.modules.dev.idea = with types; { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}".home = {
      file.".ideavimrc".source = ../../configs/idea/ideavimrc;
    };
  };
}
