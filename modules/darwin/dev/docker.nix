{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.docker;
in
{
  options.modules.dev.docker = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    hm = {
      home = {
        packages = with pkgs; [ docker ];
      };

      programs = {
        zsh.shellAliases = mkIf config.modules.shell.zsh.enable { dc = "docker compose"; };
        fish.shellAbbrs = mkIf config.modules.shell.fish.enable { dc = "docker compose"; };
      };
    };

    modules = mkIf config.modules.homebrew.enable {
      homebrew = {
        casks = [ "docker" ];
      };
    };
  };
}
