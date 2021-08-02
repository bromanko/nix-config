{ pkgs, config, lib, home-manager, ... }:

with lib;
with lib.my; {
  modules = { shell.zsh.enable = true; };
  home-manager.users.${config.user.name} = { };
}
