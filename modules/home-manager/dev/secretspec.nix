{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.secretspec;
  tomlFormat = pkgs.formats.toml { };
  configFile = tomlFormat.generate "secretspec-config.toml" cfg.settings;
in
{
  options.modules.dev.secretspec = with types; {
    enable = mkBoolOpt false;

    package = mkOption {
      type = package;
      default = pkgs.secretspec;
      description = "SecretSpec package to install";
    };

    settings = mkOption {
      type = tomlFormat.type;
      default = { };
      description = "SecretSpec user configuration; secret values must not be stored here";
    };
  };

  config = mkIf cfg.enable {
    hm = {
      # Devenv also exposes a SecretSpec executable. Prefer the explicitly
      # configured package when both are installed.
      home.packages = [ (hiPrio cfg.package) ];

      xdg.configFile."secretspec/config.toml".source = configFile;
    };
  };
}
