{ config, lib, pkgs, ... }:

{
  imports = [ ../../../home ];
  # imports = [ ../../home.nix ../home-darwin.nix ];

  networking.computerName = "bromanko Macbook Pro";
  networking.hostName = "bromanko-macbook-pro";

  environment.variables.PROJECTS = "$HOME/Code";
}
