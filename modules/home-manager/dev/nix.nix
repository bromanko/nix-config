{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.nix;
in
{
  options.modules.dev.nix = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
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
