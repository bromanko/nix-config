{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.ragenix;
in
{
  imports = [
    inputs.ragenix.nixosModules.age
    (lib.mkAliasOptionModule [ "modules" "ragenix" "secrets" ] [ "age" "secrets" ])
  ];

  options.modules.ragenix = {
    enable = mkBoolOpt false;

    # Path to age secrets directory
    # secretsDir = mkOpt' types.str "/etc/ragenix" "Directory containing encrypted age secrets";

    # # Path to age identity file(s)
    # identityPaths = mkOpt' (types.listOf types.str) [
    #   "/etc/ragenix/key.txt"
    # ] "List of paths to age identity files";

    # # Path to public ragenix keys
    # publicKeys = mkOpt' (types.listOf types.str) [ ] "List of paths to public age keys";
  };

  config = mkIf cfg.enable {
    age = {
      ageBin = "${pkgs.my.age-with-plugins}/bin/age";
      # identityPaths = cfg.identityPaths;
      # secretsDir = cfg.secretsDir;
      # secretsMountPoint = cfg.secretsDir;
      # publicKeys = cfg.publicKeys;
    };

    hm = {
      home = {
        packages = with pkgs; [ my.age-with-plugins ];
      };

      xdg.configFile = {
        "age/age-identity.txt".source = ../configs/age/age-identity.txt;
      };
    };
  };
}
