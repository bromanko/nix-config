{ config, lib, pkgs, inputs, ... }:

{
  imports = [ ] ++ (lib.my.mapModulesRec' (toString ../home-manager)
    (p: import p { inherit config lib pkgs inputs; }));
}
