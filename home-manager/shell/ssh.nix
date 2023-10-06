{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.ssh;
in {
  config = mkIf cfg.enable {
    programs.ssh = {
      enable = true;

      forwardAgent = true;

      matchBlocks = {
        keychain = {
          host = "*";
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
