{ config, options, lib, pkgs, ... }:

{
  users.users.${config.user.name} = {
    isNormalUser = true;
    extraGroups = [ "wheel" ];
    home = "/home/${config.user.name}";
    shell = pkgs.fish;
    openssh = {
      authorizedKeys.keys = [
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAID2vkvKlul2zm/Qx7V0NmmwGDJcFY46tf9asOVONkcCK Meta MacBook Pro 16"
        "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIPzLxgUGkWXC/Hkvuxv4rsJfFYrYq1S16DouIXRXD2Ia Personal MacBook Air"
      ];
    };
  };
}
