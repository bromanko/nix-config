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
    enable = mkBoolOpt false;
    
    system = {
      package = mkOpt package pkgs.nixVersions.latest;
      optimise = mkBoolOpt true;
    };

    dev = {
      enable = mkBoolOpt false;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # System-level nix configuration
    {
      nix = {
        package = cfg.system.package;
        
        # Optimizations
        optimise.automatic = cfg.system.optimise;
        
        extraOptions = ''
          experimental-features = nix-command flakes
          keep-derivations = true
          keep-outputs = true
        '' + optionalString pkgs.stdenv.isDarwin ''
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
  ]);
}