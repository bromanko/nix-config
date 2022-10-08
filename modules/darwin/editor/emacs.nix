{ config, pkgs, lib, inputs, ... }:

with lib;

let cfg = config.modules.editor.emacs;
in {
  config = mkIf cfg.enable {
    nixpkgs.overlays = [ inputs.emacs-overlay-darwin.overlay ];
    nix.settings = {
      substituters = [ "https://cachix.org/api/v1/cache/emacs" ];
      trusted-public-keys =
        [ "emacs.cachix.org-1:b1SMJNLY/mZF6GxQE+eDBeps7WnkT0Po55TAyzwOxTY=" ];
    };

    home-manager.users."${config.user.name}" = {
      programs.emacs = {
        enable = true;
        package = pkgs.emacs;
      };
    };
  };
}
