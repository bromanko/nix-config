{ config, lib, pkgs, ... }:

{
  imports = [ ] ++ (lib.my.mapModulesRec' (toString ../home-manager) import);
}
