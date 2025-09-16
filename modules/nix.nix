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
        default = null; # null represents "disabled"
        description = "Controls the system-level Nix configuration. Possible values: 'determinate', 'default', or null (disabled).";
      };

      optimise = mkBoolOpt true;
    };

    dev = {
      enable = mkBoolOpt true;
    };
  };

  config = mkMerge [
    # Case 1: "determinate"
    (mkIf (cfg.system.enable == "determinate") {
      nix.enable = false;

      determinate-nix.customSettings = {
        extra-experimental-features = "external-builders";
        external-builders = builtins.toJSON [
          {
            systems = [
              "aarch64-linux"
              "x86_64-linux"
            ];
            program = "/usr/local/bin/determinate-nixd";
            args = [ "builder" ];
          }
        ];
        flake-registry = "/etc/nix/flake-registry.json";
        keep-outputs = true;
        extra-substituters = "https://devenv.cachix.org";
        extra-trusted-public-keys = "devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=";
      };
    })

    # Case 2: "default" or null
    (mkIf (cfg.system.enable == "default" || cfg.system.enable == null) {
      nix.enable = cfg.system.enable or null;

      nix = {
        optimise.automatic = cfg.system.optimise;

        extraOptions = ''
          experimental-features = nix-command flakes
          keep-derivations = true
          keep-outputs = true
          extra-substituters = https://devenv.cachix.org
          extra-trusted-public-keys = devenv.cachix.org-1:w1cLUi8dv3hnoSPGAuibQv+f9TZLr6cv/Hm9XgU50cw=
        ''
        + optionalString pkgs.stdenv.isDarwin ''
          extra-platforms = x86_64-darwin aarch64-darwin
        '';
      };

      # User nix configuration via homeage
      # If homeage is not enabled, this will not be placed
      modules.homeage = {
        file = {
          "nix.config" = {
            source = ../configs/nix/nix.conf.age;
            symlinks = [ "$HOME/.config/nix/nix.conf" ];
          };
        };
      };
    })

    # Development tools
    (mkIf cfg.dev.enable {
      hm = {
        home = {
          packages = with pkgs; [
            nixfmt-rfc-style
            nix-output-monitor
            nil
          ];
        };
      };
    })
  ];
}
