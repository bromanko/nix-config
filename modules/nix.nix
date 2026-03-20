{
  config,
  options,
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
  imports = [
    ./home-manager-nix.nix
  ];

  config = mkMerge [
    # Case 1: "determinate"
    # Note: external-builders is now managed by determinate-nixd itself and cannot
    # be customized via customSettings in newer versions of the determinate module.
    # On darwin, enable Determinate Nix explicitly and hand off nix.conf management.
    # On NixOS, the upstream module uses `determinate.enable` instead.
    (mkIf (cfg.system.enable == "determinate") (
      optionalAttrs (options ? determinate) {
        determinate.enable = true;
      }
      // optionalAttrs (options ? determinateNix) {
        nix.enable = false;
        determinateNix.customSettings = {
          flake-registry = "/etc/nix/flake-registry.json";
          keep-outputs = true;
          extra-substituters = cfg.caches.extraSubstituters;
          extra-trusted-public-keys = cfg.caches.extraTrustedPublicKeys;
        };
      }
    ))

    # Case 2: "default" or null
    (mkIf (cfg.system.enable == "default" || cfg.system.enable == null) (
      {
        nix.enable = if cfg.system.enable == "default" then true else null;
      }
      // optionalAttrs (options ? determinate) {
        determinate.enable = false;
      }
      // {
        nix = {
          optimise.automatic = cfg.system.optimise;

          gc = {
            automatic = true;
            options = "--delete-older-than 7d";
          }
          // optionalAttrs pkgs.stdenv.hostPlatform.isLinux {
            dates = "weekly";
          }
          // optionalAttrs pkgs.stdenv.hostPlatform.isDarwin {
            interval = {
              Weekday = 0;
              Hour = 2;
              Minute = 0;
            };
          };

          extraOptions = ''
            experimental-features = nix-command flakes
            keep-derivations = true
            keep-outputs = true
            extra-substituters = ${cfg.caches.extraSubstituters}
            extra-trusted-public-keys = ${cfg.caches.extraTrustedPublicKeys}
          ''
          + optionalString pkgs.stdenv.hostPlatform.isDarwin ''
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
      }
    ))
  ];
}
