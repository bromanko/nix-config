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

    windowRules = mkOption {
      type = types.listOf types.attrs;
      default = [ ];
      description = "Window detection rules for automatic workspace assignment";
    };

    gaps = {
      inner = {
        horizontal = mkOption {
          type = types.int;
          default = 13;
          description = "Horizontal inner gap size";
        };
        vertical = mkOption {
          type = types.int;
          default = 13;
          description = "Vertical inner gap size";
        };
      };
      outer = {
        left = mkOption {
          type = types.int;
          default = 3;
          description = "Left outer gap size";
        };
        right = mkOption {
          type = types.int;
          default = 3;
          description = "Right outer gap size";
        };
        top = mkOption {
          type = types.int;
          default = 3;
          description = "Top outer gap size";
        };
        bottom = mkOption {
          type = types.int;
          default = 3;
          description = "Bottom outer gap size";
        };
      };
    };
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
          inner.horizontal = cfg.gaps.inner.horizontal;
          inner.vertical = cfg.gaps.inner.vertical;
          outer.left = cfg.gaps.outer.left;
          outer.bottom = cfg.gaps.outer.bottom;
          outer.top = cfg.gaps.outer.top;
          outer.right = cfg.gaps.outer.right;
        };
        after-startup-command = [
          "exec-and-forget ${pkgs.jankyborders}/bin/borders active_color=0xfff9e2af inactive_color=0x00000000 width=5.0 style=round hidpi=on"
        ];
        on-window-detected = cfg.windowRules;
      };
    };
  };
}
