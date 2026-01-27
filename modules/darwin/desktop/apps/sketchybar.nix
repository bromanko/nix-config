{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.sketchybar;
in
{
  options.modules.desktop.apps.sketchybar = {
    enable = mkBoolOpt false;

    package = mkOption {
      type = types.package;
      default = pkgs.sketchybar;
      description = "The sketchybar package to use.";
    };

    extraPackages = mkOption {
      type = types.listOf types.package;
      default = [ ];
      description = "Extra packages to add to sketchybar's PATH.";
    };
  };

  config = mkIf cfg.enable {
    services.sketchybar = {
      enable = true;
      package = cfg.package;
      extraPackages = cfg.extraPackages;
    };

    # Auto-hide system menu bar so sketchybar is visible
    system.defaults.NSGlobalDomain._HIHideMenuBar = true;

    # SF Symbols font for icons
    modules.homebrew.casks = [ "sf-symbols" ];

    hm.home.file.".config/sketchybar".source =
      config.hm.lib.file.mkNixConfigSymlink ../../../../configs/sketchybar;
  };
}
