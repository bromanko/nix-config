{
  config,
  pkgs,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.shell.bat;
  shellAliases = {
    cat = "${pkgs.bat}/bin/bat";
    "cat!" = "command cat";
  };
in
{
  options.modules.shell.bat = with types; {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      programs.bat = {
        enable = true;
        config = {
          theme = "Monokai Extended";
        };
      };

      programs.zsh.shellAliases = mkIf config.modules.shell.zsh.enable shellAliases;
      programs.fish.shellAliases = mkIf config.modules.shell.fish.enable shellAliases;
    };
  };
}
