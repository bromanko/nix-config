{ config, lib, inputs, pkgs, ... }:

with lib;
let cfg = config.modules.homeage;
in {
  imports = [ inputs.homeage.homeManagerModules.homeage ];
  config = mkIf cfg.enable {
    homeage = {
      inherit (cfg) installationType file;

      pkg = pkgs.my.age-with-plugins;

      mount = if pkgs.hostPlatform.isDarwin then
        "$HOME/.config/age/secrets"
      else
        "/run/user/$UID/secrets";

      identityPaths = [ "$HOME/.config/age/age-identity.txt" ];
    };

    home = { packages = with pkgs; [ my.age-with-plugins ]; };

    xdg.configFile = {
      "age/age-identity.txt".source = ../configs/age/age-identity.txt;
    };
  };
}
