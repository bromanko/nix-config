{ config, pkgs, lib, ... }:

with lib;

let cfg = config.modules.editor.emacs;
in {
  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}" = {
      programs.emacs = with pkgs; {
        enable = true;
        package = emacs-git;
        extraPackages = epkgs: [ epkgs.vterm ];
      };
      # needed to compile vterm
      home.packages = with pkgs; [ libtool ];
    };
  };
}

