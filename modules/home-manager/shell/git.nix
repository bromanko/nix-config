{ config, lib, pkgs, ... }:

with lib;
with lib.my; {
  options.modules.shell.git = {
    enable = mkBoolOpt false;

    userEmail = mkOption {
      type = types.str;
      default = "hello@bromanko.com";
    };

    userName = mkOption {
      type = types.str;
      default = "Brian Romanko";
    };

    gitHubUser = mkOption {
      type = types.str;
      default = "bromanko";
    };
  };
}
