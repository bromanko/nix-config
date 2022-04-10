{ config, pkgs, lib, inputs, ... }:

with lib;
with lib.my;
let cfg = config.modules.editor.emacs;

in {
  config = mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.emacs-overlay.overlay ];
    home-manager.users."${config.user.name}" = {
      home.packages = with pkgs; [
        binutils # native-comp needs "as", provided here
        ((emacsPackagesFor emacsPgtkGcc).emacsWithPackages
          (epkgs: [ epkgs.vterm ]))
      ];
    };
  };
}
