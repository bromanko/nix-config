{ pkgs, config, lib, home-manager, ... }:

with lib;
with lib.my; {
  home-manager.users.${config.user.name} = { };
}
