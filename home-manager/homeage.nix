{ config, lib, inputs, pkgs, ... }:

with lib;
let cfg = config.modules.homeage;
in {
  imports = [ inputs.homeage.homeManagerModules.homeage ];
  config = mkIf cfg.enable {
    homeage = { inherit (cfg) installationType; };

    home = { packages = with pkgs; [ my.age-with-plugins my.age-plugin-op ]; };
  };
}
