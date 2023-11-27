{ config, lib, pkgs, ... }:

with lib;
with lib.my;
let cfg = config.modules.shell.fish;
in {
  options.modules.shell.fish = with types; {
    enable = mkBoolOpt false;

    projectsPath =
      mkOpt' str "$HOME/Code" "Directory containing project files.";

    extraPaths = mkOption {
      type = listOf str;
      example = "$HOME/bin";
      default = [ ];
      description = "Additional paths to add to <envar>PATH</envar.";
    };
  };
}
