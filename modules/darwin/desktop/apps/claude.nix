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
  desktopConfig = ../../../../configs/claude/claude_desktop_config.json;
  desktopConfigPath = "${config.hm.home.homeDirectory}/Library/Application Support/Claude/claude_desktop_config.json";
in
{
  options.modules.desktop.apps.claude = {
    enable = mkBoolOpt false;
  };

  config = mkIf (cfg.enable && pkgs.stdenv.hostPlatform.isDarwin) {
    modules.homebrew = {
      casks = [ "claude" ];
    };

    home-manager.users."${config.user.name}".home.activation.configureClaudeDesktop =
      lib.hm.dag.entryAfter [ "linkGeneration" ]
        ''
          config_file=${escapeShellArg desktopConfigPath}
          ${pkgs.coreutils}/bin/mkdir -p "$(${pkgs.coreutils}/bin/dirname "$config_file")"

          existing="$config_file"
          if [ ! -f "$existing" ]; then
            existing="${pkgs.writeText "empty-claude-desktop-config.json" "{}"}"
          fi

          temporary="$(${pkgs.coreutils}/bin/mktemp "$config_file.XXXXXX")"
          if ! ${pkgs.jq}/bin/jq -e -s '
            if length == 2 and (.[0] | type) == "object" and (.[1] | type) == "object"
            then .[0] * .[1]
            else error("Claude Desktop config must contain JSON objects")
            end
          ' "$existing" "${desktopConfig}" > "$temporary"; then
            ${pkgs.coreutils}/bin/rm -f "$temporary"
            exit 1
          fi

          ${pkgs.coreutils}/bin/chmod 600 "$temporary"
          if [ -f "$config_file" ] && ${pkgs.diffutils}/bin/cmp -s "$config_file" "$temporary"; then
            ${pkgs.coreutils}/bin/rm -f "$temporary"
          else
            ${pkgs.coreutils}/bin/mv -f "$temporary" "$config_file"
          fi
        '';
  };
}
