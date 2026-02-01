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
        default = null;
        description = "Controls the desired system-level Nix configuration; ignored in standalone home-manager mode.";
      };

      optimise = mkBoolOpt true;
    };

    dev = {
      enable = mkBoolOpt true;
    };
  };

  config = mkMerge [
    (mkIf cfg.dev.enable {
      hm = {
        home = {
          packages = with pkgs; [
            nixfmt
            nix-output-monitor
            nil
          ];
        };
      };
    })

    # In standalone home-manager mode (Linux), determinateNix.customSettings is
    # not available. Write substituter config to ~/.config/nix/nix.conf so the
    # nix daemon picks up our extra binary caches. On darwin, the system-level
    # nix module handles this via determinateNix.customSettings or nix.extraOptions.
    (mkIf (cfg.system.enable == "determinate" && pkgs.stdenv.hostPlatform.isLinux) {
      hm.xdg.configFile."nix/nix.conf".text = ''
        extra-substituters = ${cfg.caches.extraSubstituters}
        extra-trusted-public-keys = ${cfg.caches.extraTrustedPublicKeys}
      '';
    })
  ];
}
