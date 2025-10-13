{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.aerospace;
in
{
  options.modules.desktop.apps.aerospace = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.jankyborders ];

    services.aerospace = {
      enable = true;
      settings = {
        automatically-unhide-macos-hidden-apps = true;
        key-mapping = {
          key-notation-to-key-code = {
            # colemak is not supported yet in nix-darwin
            h = "m";
            j = "n";
            k = "e";
            l = "i";
          };
        };
        mode.main.binding = {
          alt-slash = "layout tiles horizontal vertical";
          alt-comma = "layout accordion horizontal vertical";

          alt-h = "focus left";
          alt-j = "focus down";
          alt-k = "focus up";
          alt-l = "focus right";

          alt-shift-h = "move left";
          alt-shift-j = "move down";
          alt-shift-k = "move up";
          alt-shift-l = "move right";

          alt-shift-left = "focus left";
          alt-shift-down = "focus down";
          alt-shift-up = "focus up";
          alt-shift-right = "focus right";

          alt-minus = "resize smart -50";
          alt-equal = "resize smart +50";

          alt-f = "fullscreen";

          alt-1 = "workspace 1";
          alt-2 = "workspace 2";
          alt-3 = "workspace 3";
          alt-4 = "workspace 4";
          alt-5 = "workspace 5";
          alt-6 = "workspace 6";
          alt-7 = "workspace 7";
          alt-8 = "workspace 8";
          alt-9 = "workspace 9";
          alt-0 = "workspace 10";

          alt-shift-1 = "move-node-to-workspace 1";
          alt-shift-2 = "move-node-to-workspace 2";
          alt-shift-3 = "move-node-to-workspace 3";
          alt-shift-4 = "move-node-to-workspace 4";
          alt-shift-5 = "move-node-to-workspace 5";
          alt-shift-6 = "move-node-to-workspace 6";
          alt-shift-7 = "move-node-to-workspace 7";
          alt-shift-8 = "move-node-to-workspace 8";
          alt-shift-9 = "move-node-to-workspace 9";

          alt-tab = "workspace-back-and-forth";
          alt-shift-tab = "move-workspace-to-monitor --wrap-around next";
        };
        gaps = {
          inner.horizontal = 13;
          inner.vertical = 13;
          outer.left = 3;
          outer.bottom = 3;
          outer.top = 3;
          outer.right = 3;
        };
        after-startup-command = [
          "exec-and-forget ${pkgs.jankyborders}/bin/borders active_color=0xff89b4fa inactive_color=0xff45475a width=5.0 style=round hidpi=on"
        ];
        on-window-detected = [
          {
            "if".app-id = "app.zen-browser.zen";
            run = "move-node-to-workspace 1";
          }
          {
            "if".app-id = "com.google.Chrome";
            run = "move-node-to-workspace 1";
          }
          {
            "if".app-id = "dev.zed.Zed-Preview";
            run = "move-node-to-workspace 2";
          }
          {
            "if".app-id = "com.mitchellh.ghostty";
            run = "move-node-to-workspace 3";
          }
          {
            # Catch-all: move everything else to workspace 5
            run = "move-node-to-workspace 5";
          }
        ];
      };
    };
  };
}
