{ config, lib, inputs, ... }:

with lib;
let cfg = config.modules.homeage;
in {
  imports = [ inputs.homeage.homeManagerModules.homeage ];
  config = mkIf cfg.enable { };
}
