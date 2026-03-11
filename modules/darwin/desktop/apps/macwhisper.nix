{
  config,
  lib,
  pkgs,
  inputs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.desktop.apps.macwhisper;
  homeDir = "/Users/${config.user.name}";
  logsDir = "${homeDir}/Library/Logs";
  stdoutLog = "${logsDir}/sst-gateway.stdout.log";
  stderrLog = "${logsDir}/sst-gateway.stderr.log";
  gatewayPort = toString cfg.gateway.port;
  gatewayBaseUrl = "http://${cfg.gateway.host}:${gatewayPort}/v1";
  gatewayPkg = inputs.sst-gateway.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.modules.desktop.apps.macwhisper = with types; {
    enable = mkBoolOpt false;

    gateway = {
      host = mkOption {
        type = str;
        default = "127.0.0.1";
        description = "Host address for the local sst-gateway service.";
      };

      port = mkOption {
        type = port;
        default = 19476;
        description = "Port for the local sst-gateway service.";
      };

      model = mkOption {
        type = str;
        default = "moonshine-en";
        description = "Model identifier written into MacWhisper's custom dictation provider settings.";
      };
    };
  };

  config = mkIf cfg.enable {
    modules.homebrew.casks = [ "macwhisper" ];

    environment.systemPackages = [ gatewayPkg ];

    environment.etc."newsyslog.d/sst-gateway.conf".text = ''
      # logfile                                owner:group            mode count size when flags
      ${stdoutLog}                             ${config.user.name}:staff 644  3     1024 *    N
      ${stderrLog}                             ${config.user.name}:staff 644  3     1024 *    N
    '';

    launchd.user.agents.sst-gateway = {
      serviceConfig = {
        ProgramArguments = [ "${gatewayPkg}/bin/sst-gateway" ];
        EnvironmentVariables = {
          SST_GATEWAY_HOST = cfg.gateway.host;
          SST_GATEWAY_PORT = gatewayPort;
        };
        RunAtLoad = true;
        KeepAlive = true;
        WorkingDirectory = homeDir;
        StandardOutPath = stdoutLog;
        StandardErrorPath = stderrLog;
      };
    };

    # MacWhisper does not currently document declarative cloud-transcription
    # settings for a custom local provider, so we write the observed defaults
    # keys directly. We only point Dictation at the custom provider and leave
    # regular transcription selection untouched.
    system.activationScripts.postActivation.text = mkAfter ''
      defaults write com.goodsnooze.MacWhisper configuredCloudTranscriptionProviders -array '"custom"'
      defaults write com.goodsnooze.MacWhisper customOpenAIWhisperProviderBaseURL -string '${gatewayBaseUrl}'
      defaults write com.goodsnooze.MacWhisper customOpenAIWhisperProviderModel -string '${cfg.gateway.model}'
      defaults write com.goodsnooze.MacWhisper dictationKeyboardButton -string '"custom"'
      defaults write com.goodsnooze.MacWhisper dictationRunnerConfig -string '{"engine":{"customOpenaiCloud":{}},"language":{"specific":"en"}}'
      killall cfprefsd >/dev/null 2>&1 || true
    '';
  };
}
