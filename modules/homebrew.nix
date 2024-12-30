{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
{
  options.modules.homebrew = with types; {
    enable = mkBoolOpt false;

    brewPrefix = mkOption {
      type = str;
      default = "/usr/local/bin";
      description = ''
        Customize path prefix where executable of <command>brew</command> is searched for.
      '';
    };

    taps = mkOption {
      type = listOf str;
      default = [ ];
      example = [ "homebrew/cask-versions" ];
      description = "Homebrew formula repositories to tap.";
    };

    brews = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [ "mas" ];
      description = "Homebrew brews to install.";
    };

    casks = mkOption {
      type = with types; listOf str;
      default = [ ];
      example = [
        "hammerspoon"
        "virtualbox"
      ];
      description = "Homebrew casks to install.";
    };
  };
}
