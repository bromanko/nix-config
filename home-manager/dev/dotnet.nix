{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.dev.dotnet;
in {
  config = mkIf cfg.enable {
    home = { packages = with pkgs; [ dotnetCorePackages.sdk_6_0 mono ]; };
  };
}
