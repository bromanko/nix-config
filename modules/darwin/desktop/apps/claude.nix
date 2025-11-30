{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.claude;
in
{
  options.modules.desktop.apps.claude = {
    enable = mkBoolOpt false;
  };

  config = mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isDarwin) {
    modules.homebrew = {
      casks = [ "claude" ];
    };

    home-manager.users."${config.user.name
    }".home.file."Library/Application Support/Claude/claude_desktop_config.json" =
      {
        source = ../../../../configs/claude/claude_desktop_config.json;
      };
  };
}
