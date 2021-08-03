{ config, pkgs, lib, ... }:

with lib;
with lib.my;
let cfg = config.modules.editor.emacs;

in {
  options.modules.editor.emacs = with types; { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    home-manager.users."${config.user.name}" = {
      programs.emacs = {
        enable = true;
        package = if config.systemType == "darwin" then
          pkgs.emacsMacport
        else
          pkgs.emacs;
      };
      home.file.".doom.d".source = ../../configs/emacs/doom.d;
    };
  };
}
