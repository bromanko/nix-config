{ lib, ... }:
{
  imports = [ ../lima-scherzo ];
  networking.hostName = lib.mkForce "lima-scherzo-2";
}
