{
  config,
  lib,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.omniwm;
in
{
  options.modules.desktop.apps.omniwm.enable = mkBoolOpt false;

  config = mkIf cfg.enable {
    modules.homebrew.casks = [ "omniwm" ];

    # Give OmniWM separate Spaces per display and the vertical trackpad swipe.
    system.defaults.spaces.spans-displays = mkForce false;
    system.defaults.dock.showMissionControlGestureEnabled = false;

    hm.xdg.configFile."omniwm/settings.toml".source =
      config.hm.lib.file.mkNixConfigSymlink "/configs/omniwm/settings.toml";
  };
}
