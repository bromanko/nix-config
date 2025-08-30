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
      enable = mkBoolOpt true;
      optimise = mkBoolOpt true;
    };

    dev = {
      enable = mkBoolOpt true;
    };
  };

  config = (
    mkMerge [
      {
        nix.enable = cfg.system.enable;
      }

      # System-level nix configuration
      {
        nix = mkIf cfg.system.enable {
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
      }

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

      # User nix configuration via homeage
      # If homeage is not enabled, this will not be placed
      {
        modules.homeage = {
          file = {
            "nix.config" = {
              source = ../configs/nix/nix.conf.age;
              symlinks = [ "$HOME/.config/nix/nix.conf" ];
            };
          };
        };
      }
    ]
  );
}
