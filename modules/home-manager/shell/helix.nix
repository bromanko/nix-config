{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.helix;
in {
  options.modules.shell.helix = { enable = mkBoolOpt false; };

  config = mkIf cfg.enable {
    hm = {
      programs.helix = {
        enable = true;
        extraPackages = with pkgs; [ helix-gpt ];
        settings = {
          theme = "catppuccin_mocha";
          editor = { line-number = "relative"; };
        };
      };
    };
  };
}
