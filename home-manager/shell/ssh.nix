{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.ssh;
in
{
  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;

      forwardAgent = true;
      controlMaster = "auto";
      controlPersist = "1800";

      matchBlocks = {
        keychain = {
          host = "github github.com";
          extraOptions = {
            IgnoreUnknown = "UseKeychain";
            AddKeysToAgent = "yes";
            UseKeychain = "yes";
          };
        };
      };
    };
  };
}
