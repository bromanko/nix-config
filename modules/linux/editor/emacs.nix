{ config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.editor.emacs;

in {
  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}" = {
      home.packages = with pkgs; [
        binutils # native-comp needs "as", provided here
        ((emacsPackagesFor emacs-pgtk).emacsWithPackages
          (epkgs: [ epkgs.vterm ]))
      ];
    };
  };
}
