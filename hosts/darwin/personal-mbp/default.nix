{ config, lib, pkgs, home-manager, ... }:

let
  user = "";
  d = home-manager.darwinModules.home-manager {
    home-manager.useGlobalPkgs = true;
    home-manager.users.${user} = {
      imports = [ ../modules/home-manager/bat.nix ];

      # This value determines the Home Manager release that your
      # configuration is compatible with. This helps avoid breakage when
      # a new Home Manager release introduces backwards incompatible changes.
      #
      # You can update Home Manager without changing this value. See the
      # Home Manager release notes for a list of state version changes
      # in each release.
      home.stateVersion = "21.11";
    };
  };
in d
