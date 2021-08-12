{ config, pkgs, lib, ... }:

{
  home-manager.users."${config.user.name}" = {
    programs.emacs = {
      enable = true;
      package = pkgs.emacsMacport;
    };
  };
}
