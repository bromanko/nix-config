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
      enable = mkBoolOpt true;
      package = mkOpt package (
        if pkgs.stdenv.isDarwin then pkgs.nixVersions.latest else pkgs.nix
      );
      optimise = mkBoolOpt pkgs.stdenv.isDarwin;
    };

    dev = {
      enable = mkBoolOpt false;
    };

    userConfig = {
      enable = mkBoolOpt false;
    };
  };

  config = mkIf cfg.enable (mkMerge [
    # System-level nix configuration
    (mkIf cfg.system.enable {
      nix = {
        package = cfg.system.package;
        
        # Darwin-specific optimizations
        optimise.automatic = mkIf pkgs.stdenv.isDarwin cfg.system.optimise;
        
        extraOptions = ''
          experimental-features = nix-command flakes
          keep-derivations = true
          keep-outputs = true
        '' + optionalString pkgs.stdenv.isDarwin ''
          extra-platforms = x86_64-darwin aarch64-darwin
        '';
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

    # User nix configuration via homeage
    (mkIf cfg.userConfig.enable {
      modules.homeage = {
        file = {
          "nix.config" = {
            source = ../configs/nix/nix.conf.age;
            symlinks = [ "$HOME/.config/nix/nix.conf" ];
          };
        };
      };
    })
  ]);
}