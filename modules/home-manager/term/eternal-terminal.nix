{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.term.eternal-terminal.client;
in
{
  options.modules.term.eternal-terminal.client = with types; {
    enable = mkBoolOpt false;

    package = mkOption {
      type = package;
      default = pkgs.eternal-terminal;
      description = "Eternal Terminal package to install for client use.";
    };
  };

  config = mkIf cfg.enable {
    hm.home.packages = [ cfg.package ];
  };
}
