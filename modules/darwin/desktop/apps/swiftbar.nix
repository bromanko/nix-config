{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.swiftbar;
  buildkiteCfg = cfg.buildkite;

  pluginDirectory = "${config.hm.home.homeDirectory}/Library/Application Support/SwiftBar/Plugins";
  homeageMount = replaceStrings [ "$HOME" ] [ config.hm.home.homeDirectory ] config.hm.homeage.mount;
  buildkiteTokenFile = "${homeageMount}/buildkite-api-token";
  buildkiteApiUrl =
    "https://api.buildkite.com/v2/organizations/${buildkiteCfg.organization}/pipelines/${buildkiteCfg.pipeline}/builds"
    + "?per_page=1&exclude_jobs=true";
  buildkitePipelineUrl = "https://buildkite.com/${buildkiteCfg.organization}/${buildkiteCfg.pipeline}";

  buildkitePlugin = pkgs.writeShellApplication {
    name = "buildkite-status";
    runtimeInputs = with pkgs; [
      coreutils
      curl
      jq
    ];
    text = ''
      token_file=${escapeShellArg buildkiteTokenFile}
      api_url=${escapeShellArg buildkiteApiUrl}
      pipeline_url=${escapeShellArg buildkitePipelineUrl}
      display_name=${escapeShellArg buildkiteCfg.displayName}

      render_error() {
        reason="$1"
        printf '| sfimage=exclamationmark.triangle.fill sfcolor=#E5A50A tooltip="%s: %s"\n' "$display_name" "$reason"
        printf '%s: unavailable\n' "$display_name"
        printf '%s\n' "$reason"
        printf -- '---\n'
        printf 'Open pipeline | href=%s\n' "$pipeline_url"
        printf 'Refresh | refresh=true\n'
      }

      if [ ! -r "$token_file" ]; then
        render_error "Buildkite API token is unavailable"
        exit 0
      fi

      token="$(tr -d '\r\n' < "$token_file")"
      if [ -z "$token" ]; then
        render_error "Buildkite API token is empty"
        exit 0
      fi

      response_file="$(mktemp)"
      trap 'rm -f "$response_file"' EXIT

      fetch_builds() {
        printf 'header = "Authorization: Bearer %s"\n' "$token" |
          curl \
            --config - \
            --silent \
            --show-error \
            --connect-timeout 5 \
            --max-time 15 \
            --output "$response_file" \
            --write-out '%{http_code}' \
            "$@" \
            "$api_url"
      }

      check_response() {
        case "$1" in
          200)
            return 0
            ;;
          401 | 403)
            render_error "Buildkite API authentication failed"
            ;;
          *)
            render_error "Buildkite API returned HTTP $1"
            ;;
        esac
        return 1
      }

      if ! http_status="$(fetch_builds)"; then
        render_error "Could not reach the Buildkite API"
        exit 0
      fi
      if ! check_response "$http_status"; then
        exit 0
      fi

      if ! build="$(jq -cer 'if type == "array" and length > 0 then .[0] else error("no builds") end' "$response_file")"; then
        render_error "No builds were returned"
        exit 0
      fi

      # Buildkite lists the newest build first, which may be a feature branch.
      # If so, make one filtered request so the bar reflects the pipeline's
      # default branch rather than whichever branch ran most recently.
      default_branch="$(jq -r '.pipeline.default_branch // empty' <<< "$build")"
      branch="$(jq -r '.branch // empty' <<< "$build")"
      if [ -n "$default_branch" ] && [ "$branch" != "$default_branch" ]; then
        if ! http_status="$(fetch_builds --get --data-urlencode "branch=$default_branch")"; then
          render_error "Could not reach the Buildkite API"
          exit 0
        fi
        if ! check_response "$http_status"; then
          exit 0
        fi
        if ! build="$(jq -cer 'if type == "array" and length > 0 then .[0] else error("no builds") end' "$response_file")"; then
          render_error "No builds were returned for $default_branch"
          exit 0
        fi
      fi

      state="$(jq -r '.state // "unknown"' <<< "$build")"
      if [ "$(jq -r '.blocked // false' <<< "$build")" = "true" ]; then
        state="blocked"
      fi

      case "$state" in
        passed)
          status_label="Passed"
          status_icon="checkmark.circle.fill"
          status_color="#2EBD85"
          ;;
        running)
          status_label="Running"
          status_icon="arrow.triangle.2.circlepath.circle.fill"
          status_color="#3B82F6"
          ;;
        creating | scheduled | waiting)
          status_label="Waiting"
          status_icon="clock.fill"
          status_color="#E5A50A"
          ;;
        blocked)
          status_label="Blocked"
          status_icon="hand.raised.fill"
          status_color="#E5A50A"
          ;;
        failed | failing | waiting_failed)
          status_label="Failed"
          status_icon="xmark.octagon.fill"
          status_color="#E5484D"
          ;;
        canceled | canceling)
          status_label="Canceled"
          status_icon="slash.circle.fill"
          status_color="#8E8E93"
          ;;
        skipped | not_run)
          status_label="Skipped"
          status_icon="forward.end.circle.fill"
          status_color="#8E8E93"
          ;;
        *)
          status_label="$state"
          status_icon="questionmark.circle.fill"
          status_color="#8E8E93"
          ;;
      esac

      build_number="$(jq -r '.number' <<< "$build")"
      build_url="$(jq -r '.web_url // empty' <<< "$build")"
      branch="$(jq -r '(.branch // "unknown") | gsub("[\\r\\n|]"; " ")' <<< "$build")"
      commit="$(jq -r '(.commit // "")[:8]' <<< "$build")"
      message="$(jq -r '(.message // "(no message)") | gsub("[\\r\\n|]"; " ") | .[:120]' <<< "$build")"
      created_at="$(jq -r '.created_at // "unknown"' <<< "$build")"

      if [ -z "$build_url" ]; then
        build_url="$pipeline_url"
      fi

      printf '| sfimage=%s sfcolor=%s tooltip="%s #%s: %s"\n' \
        "$status_icon" "$status_color" "$display_name" "$build_number" "$status_label"
      printf -- '---\n'
      printf '%s #%s: %s | href=%s\n' "$display_name" "$build_number" "$status_label" "$build_url"
      printf 'Branch: %s\n' "$branch"
      if [ -n "$commit" ]; then
        printf 'Commit: %s\n' "$commit"
      fi
      printf 'Message: %s\n' "$message"
      printf 'Created: %s\n' "$created_at"
      printf -- '---\n'
      printf 'Open build | href=%s\n' "$build_url"
      printf 'Open pipeline | href=%s\n' "$pipeline_url"
      printf 'Refresh | refresh=true\n'
    '';
  };
in
{
  options.modules.desktop.apps.swiftbar = {
    enable = mkBoolOpt false;

    buildkite = {
      enable = mkBoolOpt false;

      organization = mkOption {
        type = types.str;
        example = "example-org";
        description = "Buildkite organization slug.";
      };

      pipeline = mkOption {
        type = types.str;
        example = "example-pipeline";
        description = "Buildkite pipeline slug.";
      };

      displayName = mkOption {
        type = types.str;
        default = buildkiteCfg.pipeline;
        defaultText = literalExpression "config.modules.desktop.apps.swiftbar.buildkite.pipeline";
        description = "Pipeline name shown in the SwiftBar menu.";
      };

      refreshInterval = mkOption {
        type = types.enum [
          "30s"
          "1m"
          "5m"
          "15m"
        ];
        default = "1m";
        description = "How often SwiftBar polls Buildkite.";
      };
    };
  };

  config = mkIf cfg.enable (mkMerge [
    {
      modules.homebrew.casks = [ "swiftbar" ];

      hm = {
        home.activation.configureSwiftBar = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
          mkdir -p ${escapeShellArg pluginDirectory}
          /usr/bin/defaults write com.ameba.SwiftBar PluginDirectory -string ${escapeShellArg pluginDirectory}
        '';

        launchd.agents.swiftbar = {
          enable = true;
          config = {
            ProgramArguments = [
              "/usr/bin/open"
              "-a"
              "SwiftBar"
            ];
            RunAtLoad = true;
            ProcessType = "Interactive";
          };
        };
      };
    }

    (mkIf buildkiteCfg.enable {
      assertions = [
        {
          assertion = config.modules.homeage.enable;
          message = "The SwiftBar Buildkite plugin requires modules.homeage.enable.";
        }
      ];

      hm = {
        home.file."Library/Application Support/SwiftBar/Plugins/buildkite.${buildkiteCfg.refreshInterval}.sh".source =
          "${buildkitePlugin}/bin/buildkite-status";

        homeage.file.buildkite-api-token = {
          source = ../../../../configs/buildkite/api-token.age;
        };
      };
    })
  ]);
}
