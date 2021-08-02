{ config, lib, pkgs, ... }:

{
  nixpkgs = {
    config = pkgs.config;
    overlays = pkgs.overlays;
  };
}
