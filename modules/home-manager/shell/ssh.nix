{
  config,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.ssh;
in
{
  options.modules.shell.ssh = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      programs.ssh = {
        enable = true;
        enableDefaultConfig = false;

        matchBlocks = {
          "*" = {
            forwardAgent = true;
            controlMaster = "auto";
            controlPersist = "1800";
          };
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
  };
}
