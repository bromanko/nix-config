{ config, lib, pkgs, ... }:

with lib; {
  options = with types; {
    systemType = mkOption {
      type = types.enum [ "darwin" "nixos" ];
      description = "The type of system being built.";
    };
  };
}
