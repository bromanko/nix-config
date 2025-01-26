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

        forwardAgent = true;
        controlMaster = "auto";
        controlPersist = "1800";

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
  };
}
