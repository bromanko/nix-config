{ config, pkgs, lib, ... }:

with lib;

let cfg = config.modules.editor.emacs;
in {
  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}" = {
      programs.emacs = {
        enable = true;
        package = pkgs.emacs;
        extraPackages = epkgs: [ epkgs.vterm ];
      };
    };
  };
}
