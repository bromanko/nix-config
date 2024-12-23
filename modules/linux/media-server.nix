# Initially auto-generated using compose2nix v0.3.2-pre.
{
  pkgs,
  lib,
  config,
  ...
}:

with lib;
with lib.my;
let
  cfg = config.modules.media-server;
in
{
  options.modules.media-server = {
    enable = mkBoolOpt false;
  };

  config = mkIf cfg.enable {
    # Runtime
    virtualisation.podman = {
      enable = true;
      autoPrune.enable = true;
      dockerCompat = true;
      defaultNetwork.settings = {
        # Required for container networking to be able to use names.
        dns_enabled = true;
      };
    };

    # Enable container name DNS for non-default Podman networks.
    # https://github.com/NixOS/nixpkgs/issues/226365
    networking.firewall.interfaces."podman+".allowedUDPPorts = [ 53 ];

    virtualisation.oci-containers.backend = "podman";

    # Containers
    virtualisation.oci-containers.containers."archivist-es" = {
      image = "bbilly1/tubearchivist-es";
      environment = {
        "ELASTIC_PASSWORD" = "verysecret";
        "ES_JAVA_OPTS" = "-Xms1g -Xmx1g";
        "discovery.type" = "single-node";
        "path.repo" = "/usr/share/elasticsearch/data/snapshot";
        "xpack.security.enabled" = "true";
      };
      volumes = [
        "media-server_es:/usr/share/elasticsearch/data:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=archivist-es"
        "--network=media-server_default"
      ];
    };
    systemd.services."podman-archivist-es" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-media-server_default.service"
        "podman-volume-media-server_es.service"
      ];
      requires = [
        "podman-network-media-server_default.service"
        "podman-volume-media-server_es.service"
      ];
      partOf = [
        "podman-compose-media-server-root.target"
      ];
      wantedBy = [
        "podman-compose-media-server-root.target"
      ];
    };
    virtualisation.oci-containers.containers."archivist-redis" = {
      image = "redis/redis-stack-server";
      volumes = [
        "media-server_redis:/data:rw"
      ];
      dependsOn = [
        "archivist-es"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=archivist-redis"
        "--network=media-server_default"
      ];
    };
    systemd.services."podman-archivist-redis" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-media-server_default.service"
        "podman-volume-media-server_redis.service"
      ];
      requires = [
        "podman-network-media-server_default.service"
        "podman-volume-media-server_redis.service"
      ];
      partOf = [
        "podman-compose-media-server-root.target"
      ];
      wantedBy = [
        "podman-compose-media-server-root.target"
      ];
    };
    virtualisation.oci-containers.containers."jellyfin" = {
      image = "jellyfin/jellyfin";
      volumes = [
        "media-server_jellyfin-cache:/cache:rw"
        "media-server_jellyfin-config:/config:rw"
        "media-server_media:/media:ro"
      ];
      ports = [
        "8096:8096/tcp"
      ];
      dependsOn = [
        "tubearchivist"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=jellyfin"
        "--network=media-server_default"
      ];
    };
    systemd.services."podman-jellyfin" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-media-server_default.service"
        "podman-volume-media-server_jellyfin-cache.service"
        "podman-volume-media-server_jellyfin-config.service"
        "podman-volume-media-server_media.service"
      ];
      requires = [
        "podman-network-media-server_default.service"
        "podman-volume-media-server_jellyfin-cache.service"
        "podman-volume-media-server_jellyfin-config.service"
        "podman-volume-media-server_media.service"
      ];
      partOf = [
        "podman-compose-media-server-root.target"
      ];
      wantedBy = [
        "podman-compose-media-server-root.target"
      ];
    };
    virtualisation.oci-containers.containers."tubearchivist" = {
      image = "bbilly1/tubearchivist";
      environment = {
        "ELASTIC_PASSWORD" = "verysecret";
        "ES_URL" = "http://archivist-es:9200";
        "HOST_GID" = "1000";
        "HOST_UID" = "1000";
        "REDIS_HOST" = "archivist-redis";
        "TA_HOST" = "tubearchivist.local";
        "TA_PASSWORD" = "verysecret";
        "TA_USERNAME" = "tubearchivist";
        "TZ" = "America/Los_Angeles";
      };
      volumes = [
        "media-server_cache:/cache:rw"
        "media-server_media:/youtube:rw"
      ];
      ports = [
        "8000:8000/tcp"
      ];
      dependsOn = [
        "archivist-es"
        "archivist-redis"
      ];
      log-driver = "journald";
      extraOptions = [
        "--health-cmd=[\"curl\", \"-f\", \"http://localhost:8000/health\"]"
        "--health-interval=2m0s"
        "--health-retries=3"
        "--health-start-period=30s"
        "--health-timeout=10s"
        "--network-alias=tubearchivist"
        "--network=media-server_default"
      ];
    };
    systemd.services."podman-tubearchivist" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
      };
      after = [
        "podman-network-media-server_default.service"
        "podman-volume-media-server_cache.service"
        "podman-volume-media-server_media.service"
      ];
      requires = [
        "podman-network-media-server_default.service"
        "podman-volume-media-server_cache.service"
        "podman-volume-media-server_media.service"
      ];
      partOf = [
        "podman-compose-media-server-root.target"
      ];
      wantedBy = [
        "podman-compose-media-server-root.target"
      ];
    };

    # Networks
    systemd.services."podman-network-media-server_default" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "podman network rm -f media-server_default";
      };
      script = ''
        podman network inspect media-server_default || podman network create media-server_default
      '';
      partOf = [ "podman-compose-media-server-root.target" ];
      wantedBy = [ "podman-compose-media-server-root.target" ];
    };

    # Volumes
    systemd.services."podman-volume-media-server_cache" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        podman volume inspect media-server_cache || podman volume create media-server_cache
      '';
      partOf = [ "podman-compose-media-server-root.target" ];
      wantedBy = [ "podman-compose-media-server-root.target" ];
    };
    systemd.services."podman-volume-media-server_es" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        podman volume inspect media-server_es || podman volume create media-server_es
      '';
      partOf = [ "podman-compose-media-server-root.target" ];
      wantedBy = [ "podman-compose-media-server-root.target" ];
    };
    systemd.services."podman-volume-media-server_jellyfin-cache" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        podman volume inspect media-server_jellyfin-cache || podman volume create media-server_jellyfin-cache
      '';
      partOf = [ "podman-compose-media-server-root.target" ];
      wantedBy = [ "podman-compose-media-server-root.target" ];
    };
    systemd.services."podman-volume-media-server_jellyfin-config" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        podman volume inspect media-server_jellyfin-config || podman volume create media-server_jellyfin-config
      '';
      partOf = [ "podman-compose-media-server-root.target" ];
      wantedBy = [ "podman-compose-media-server-root.target" ];
    };
    systemd.services."podman-volume-media-server_media" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        podman volume inspect media-server_media || podman volume create media-server_media
      '';
      partOf = [ "podman-compose-media-server-root.target" ];
      wantedBy = [ "podman-compose-media-server-root.target" ];
    };
    systemd.services."podman-volume-media-server_redis" = {
      path = [ pkgs.podman ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
      };
      script = ''
        podman volume inspect media-server_redis || podman volume create media-server_redis
      '';
      partOf = [ "podman-compose-media-server-root.target" ];
      wantedBy = [ "podman-compose-media-server-root.target" ];
    };

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."podman-compose-media-server-root" = {
      unitConfig = {
        Description = "Root target generated by compose2nix.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };
}
