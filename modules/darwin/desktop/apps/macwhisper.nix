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
  stdoutLog = "${logsDir}/stt-gateway.stdout.log";
  stderrLog = "${logsDir}/stt-gateway.stderr.log";
  gatewayPort = toString cfg.gateway.port;
  gatewayBaseUrl = "http://${cfg.gateway.host}:${gatewayPort}";
  gatewayPkg = inputs.stt-gateway.packages.${pkgs.stdenv.hostPlatform.system}.default;
in
{
  options.modules.desktop.apps.macwhisper = with types; {
    enable = mkBoolOpt false;

    gateway = {
      host = mkOption {
        type = str;
        default = "127.0.0.1";
        description = "Host address for the local stt-gateway service.";
      };

      port = mkOption {
        type = port;
        default = 19476;
        description = "Port for the local stt-gateway service.";
      };
    };
  };

  config = mkIf cfg.enable {
    modules.homebrew.casks = [ "macwhisper" ];

    environment.systemPackages = [ gatewayPkg ];

    environment.etc."newsyslog.d/stt-gateway.conf".text = ''
      # logfile                                owner:group            mode count size when flags
      ${stdoutLog}                             ${config.user.name}:staff 644  3     1024 *    N
      ${stderrLog}                             ${config.user.name}:staff 644  3     1024 *    N
    '';

    launchd.user.agents.stt-gateway = {
      serviceConfig = {
        ProgramArguments = [ "${gatewayPkg}/bin/stt-gateway" ];
        EnvironmentVariables = {
          STT_GATEWAY_HOST = cfg.gateway.host;
          STT_GATEWAY_PORT = gatewayPort;
        };
        RunAtLoad = true;
        KeepAlive = true;
        WorkingDirectory = homeDir;
        StandardOutPath = stdoutLog;
        StandardErrorPath = stderrLog;
      };
    };

    hm.home.activation.configureMacWhisperDictation = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
      # MacWhisper does not currently document declarative cloud-transcription
      # settings for a custom local provider, so we write the observed defaults
      # keys directly in the user's preferences domain. We only point Dictation
      # at the custom provider and leave regular transcription selection alone.
      defaults write com.goodsnooze.MacWhisper configuredCloudTranscriptionProviders -array '"custom"'
      defaults write com.goodsnooze.MacWhisper customOpenAIWhisperProviderBaseURL -string '${gatewayBaseUrl}'
      defaults delete com.goodsnooze.MacWhisper customOpenAIWhisperProviderModel >/dev/null 2>&1 || true
      defaults write com.goodsnooze.MacWhisper dictationKeyboardButton -string '"custom"'
      defaults write com.goodsnooze.MacWhisper dictationRunnerConfig -string '{"engine":{"customOpenaiCloud":{}},"language":{"specific":"en"}}'
      killall cfprefsd >/dev/null 2>&1 || true
    '';
  };
}
