{ config, options, lib, pkgs, ... }:

{
  users.users.${config.user.name} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    home = "/home/${config.user.name}";
  };
}
