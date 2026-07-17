{
  config,
  lib,
  pkgs,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.services.jellyfin;
  primaryUser = config.user.name;
  primaryGroup = "staff";
  serviceUser = "_jellyfin";
  serviceGroup = "_jellyfin";
  serviceId = 383;
  dataDir = "${cfg.stateDir}/data";
  configDir = "${cfg.stateDir}/config";
  cacheDir = "${cfg.stateDir}/cache";
  logDir = "${cfg.stateDir}/logs";
  stateDirectories = [
    cfg.stateDir
    dataDir
    configDir
    cacheDir
    logDir
  ];
in
{
  options.modules.services.jellyfin = with types; {
    enable = mkBoolOpt false;

    stateDir = mkOption {
      type = str;
      default = "/Users/Shared/media-server/jellyfin";
      description = "Mutable data, configuration, cache, and logs for Jellyfin.";
    };

    mediaDir = mkOption {
      type = str;
      default = "/Users/Shared/media-server/youtube";
      description = "Host media directory shared with the TubeArchivist container.";
    };
  };

  config = mkIf cfg.enable {
    environment.systemPackages = [ pkgs.jellyfin ];

    users.knownUsers = [ serviceUser ];
    users.knownGroups = [ serviceGroup ];
    users.groups.${serviceGroup} = {
      gid = serviceId;
      members = [ serviceUser ];
    };
    users.users.${serviceUser} = {
      uid = serviceId;
      gid = serviceId;
      description = "Jellyfin media server";
      home = cfg.stateDir;
      createHome = false;
      isHidden = true;
    };

    system.activationScripts.postActivation.text = mkAfter ''
      echo "creating Jellyfin runtime directories..."
      previous_state_owner=$(/usr/bin/stat -f '%Su:%Sg' ${escapeShellArg cfg.stateDir} 2>/dev/null || true)
      /usr/bin/install -d -o ${escapeShellArg primaryUser} -g ${escapeShellArg primaryGroup} -m 0755 \
        ${escapeShellArg cfg.mediaDir}
      /usr/bin/install -d -o ${escapeShellArg serviceUser} -g ${escapeShellArg primaryGroup} -m 0750 \
        ${escapeShellArgs stateDirectories}
      if [ "$previous_state_owner" != ${escapeShellArg "${serviceUser}:${primaryGroup}"} ]; then
        /usr/sbin/chown -R ${escapeShellArg "${serviceUser}:${primaryGroup}"} ${escapeShellArg cfg.stateDir}
      fi
    '';

    environment.etc."newsyslog.d/jellyfin.conf".text = ''
      # logfile                                owner:group                 mode count size when flags
      ${logDir}/stdout.log                     ${serviceUser}:${primaryGroup} 644  3     1024 *    N
      ${logDir}/stderr.log                     ${serviceUser}:${primaryGroup} 644  3     1024 *    N
    '';

    launchd.daemons.jellyfin = {
      serviceConfig = {
        Label = "org.nix-darwin.jellyfin";
        ProgramArguments = [
          "${pkgs.jellyfin}/bin/jellyfin"
          "--service"
          "--datadir"
          dataDir
          "--configdir"
          configDir
          "--cachedir"
          cacheDir
          "--logdir"
          logDir
        ];
        EnvironmentVariables = {
          HOME = cfg.stateDir;
          LANG = "en_US.UTF-8";
          LC_ALL = "en_US.UTF-8";
        };
        UserName = serviceUser;
        GroupName = serviceGroup;
        RunAtLoad = true;
        KeepAlive = true;
        ProcessType = "Background";
        ThrottleInterval = 10;
        StandardOutPath = "${logDir}/stdout.log";
        StandardErrorPath = "${logDir}/stderr.log";
      };
    };
  };
}
