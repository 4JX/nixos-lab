# https://recyclarr.dev/wiki/installation/docker/
{
  config,
  lib,
  ...
}:

let
  # https://recyclarr.dev/wiki/guide-configs/
  recyclarrYaml = ./recyclarr.yml;

  hsCfg = config.local.home-server;
  cfg = hsCfg.recyclarr;

  sonarrEnabled = hsCfg.sonarr.tv-hd.enable || hsCfg.sonarr.anime.enable;
  radarrEnabled = hsCfg.radarr.movies-hd.enable || hsCfg.radarr.movies-uhd.enable;

  mediaUser = config.users.users.dockermedia.uid;
  mediaGroup = config.users.groups.dockermedia.gid;
  mediaUserString = builtins.toString mediaUser;
  mediaGroupString = builtins.toString mediaGroup;
in
{
  options.local.home-server.recyclarr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = sonarrEnabled || radarrEnabled;
      description = "Whether to enable the Recyclarr service.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.recyclarr = {
      sopsFile = hsCfg.secretsFolder + "/recyclarr.yaml";
      # Serve the whole YAML file
      key = "";
      # The container will also run as the same user/group
      uid = mediaUser;
      gid = mediaGroup;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."recyclarr" = {
      image = "ghcr.io/recyclarr/recyclarr:8.5.0@sha256:5da14297a11aa910582d800f0edcb8f9e9d488642083c01dc34950f6449d9214";
      environment = {
        "TZ" = config.time.timeZone;
        # This is a default
        # - CRON_SCHEDULE=@daily
      };
      volumes = [
        "/containers/config/recyclarr:/config:rw"
        "${recyclarrYaml}:/config/recyclarr.yml:rw"
        "${config.sops.secrets.recyclarr.path}:/config/secrets.yml:rw"
      ];
      dependsOn = [
        "radarr-movies-hd"
        "sonarr-tv-hd"
        "sonarr-anime"
      ];
      user = "${mediaUserString}:${mediaGroupString}";
      log-driver = "journald";
      networks = [
        "arr"
      ];
      tryRestart = false;
    };
  };
}
