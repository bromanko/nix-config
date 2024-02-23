{ config, lib, inputs, pkgs, ... }:

with lib;
let cfg = config.modules.homeage;
in {
  imports = [ inputs.homeage.homeManagerModules.homeage ];
  config = mkIf cfg.enable {
    homeage = {
      inherit (cfg) installationType pkg file;

      mount =
        mkIf pkgs.hostPlatform.isDarwin "${config.xdg.configHome}/age/secrets"
        "/run/user/$UID/secrets";

      identityPaths = [ ];
    };

    home = { packages = with pkgs; [ my.age-with-plugins my.age-plugin-op ]; };

    xdg.configFile = {
      "age/age-identity.txt".source = ../configs/age/age-identity.txt;
    };
  };
}
