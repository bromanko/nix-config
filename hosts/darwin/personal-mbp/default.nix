{ config, lib, pkgs, ... }:

{
  imports = [ ../home.nix ../home-darwin.nix ];

  modules = {
    networking.computerName = "bromanko Macbook Pro";
    networking.hostName = "bromanko-macbook-pro";

    environment.variables.PROJECTS = "$HOME/Code";

  };
}
