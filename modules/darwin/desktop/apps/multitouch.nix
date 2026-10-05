{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.multitouch;
in
{
  options.modules.desktop.apps.multitouch = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    # Install Multitouch via Homebrew
    modules.homebrew.casks = [ "multitouch" ];

    # Disable the conflicting App Exposé gesture.
    system.activationScripts.postActivation.text = ''
      # Disable four-finger horizontal swipe (App Exposé)
      defaults write com.apple.dock showAppExposeGestureEnabled -bool false
    '';
  };
}
