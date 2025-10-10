{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.nix;

in
{
  options.modules.nix = with types; {
    system = {
      enable = mkOption {
        type = enum [
          "determinate"
          "default"
          null
        ];
        default = null;
        description = "Controls the desired system-level Nix configuration; ignored in standalone home-manager mode.";
      };

      optimise = mkBoolOpt true;
    };

    dev = {
      enable = mkBoolOpt true;
    };
  };

  config = mkIf cfg.dev.enable {
    hm = {
      home = {
        packages = with pkgs; [
          nixfmt-rfc-style
          nix-output-monitor
          nil
        ];
      };
    };
  };
}
