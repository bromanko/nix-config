{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.dev.coder;

  defaultCoderBinary =
    if pkgs.stdenv.hostPlatform.isDarwin then "/opt/homebrew/bin/coder" else "coder";

  defaultGlobalConfigPath =
    if pkgs.stdenv.hostPlatform.isDarwin then "$HOME/Library/Application Support/coderv2" else null;

  globalConfigArg = optionalString (
    cfg.ssh.globalConfigPath != null
  ) " --global-config \"${cfg.ssh.globalConfigPath}\"";
  prefixedHostPattern = "${cfg.ssh.hostPrefix}*";
  suffixedHostPattern = "*.${cfg.ssh.hostnameSuffix}";
in
{
  options.modules.dev.coder = with types; {
    enable = mkBoolOpt false;

    fishCompletions = {
      enable = mkBoolOpt true;

      file = mkOption {
        type = nullOr str;
        default =
          if pkgs.stdenv.hostPlatform.isDarwin then
            "/opt/homebrew/share/fish/vendor_completions.d/coder.fish"
          else
            null;
        description = "Path to coder fish completions file to source in interactive shells.";
      };
    };

    ssh = {
      enable = mkBoolOpt true;

      coderBinary = mkOption {
        type = str;
        default = defaultCoderBinary;
        description = "Path or command name for the coder CLI used by SSH ProxyCommand.";
      };

      globalConfigPath = mkOption {
        type = nullOr str;
        default = defaultGlobalConfigPath;
        description = "Optional path passed to coder via --global-config.";
      };

      hostPrefix = mkOption {
        type = str;
        default = "coder.";
        description = "Prefix for direct coder hostnames used with --ssh-host-prefix.";
      };

      hostnameSuffix = mkOption {
        type = str;
        default = "coder";
        description = "Suffix used for fallback *.suffix hosts with coder connect exists checks.";
      };
    };
  };

  config = mkIf cfg.enable {
    hm = {
      programs.fish.interactiveShellInit =
        mkIf (config.modules.shell.fish.enable && cfg.fishCompletions.enable) (mkAfter ''
          if type -q coder
            ${optionalString (cfg.fishCompletions.file != null) ''
            if test -r "${cfg.fishCompletions.file}"
              source "${cfg.fishCompletions.file}"
            else
            ''}
            # Homebrew coder doesn't always ship a fish completion file.
            coder completion --shell fish --print | source
            ${optionalString (cfg.fishCompletions.file != null) ''
            end
            ''}
          end
        '');

      programs.ssh = mkIf (config.modules.shell.ssh.enable && cfg.ssh.enable) {
        extraConfig = mkAfter ''
          Host ${prefixedHostPattern}
            ConnectTimeout 0
            StrictHostKeyChecking no
            UserKnownHostsFile /dev/null
            LogLevel ERROR
            ProxyCommand ${cfg.ssh.coderBinary}${globalConfigArg} ssh --stdio --ssh-host-prefix ${cfg.ssh.hostPrefix} %h

          Host ${suffixedHostPattern}
            ConnectTimeout 0
            StrictHostKeyChecking no
            UserKnownHostsFile /dev/null
            LogLevel ERROR

          Match host ${suffixedHostPattern} !exec "${cfg.ssh.coderBinary} connect exists %h"
            ProxyCommand ${cfg.ssh.coderBinary}${globalConfigArg} ssh --stdio --hostname-suffix ${cfg.ssh.hostnameSuffix} %h
        '';
      };
    };
  };
}
