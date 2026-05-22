# https://recyclarr.dev/wiki/installation/docker/
{
  config,
  lib,
  lib',
  ...
}:

let
  # https://recyclarr.dev/wiki/guide-configs/
  recyclarrYaml = ./recyclarr.yml;

  hsCfg = config.local.home-server;
  cfg = hsCfg.recyclarr;

  sonarrEnabled = hsCfg.sonarr.tv-hd.enable || hsCfg.sonarr.anime.enable;
  radarrEnabled = hsCfg.radarr.movies-hd.enable || hsCfg.radarr.movies-uhd.enable;

  mediaUser = lib'.getUser "dockermedia" "dockermedia";
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
    sops.secrets = lib'.mkContainerSecret {
      containerName = "recyclarr";
      secretName = "recyclarr";
      sopsFile = hsCfg.secretsFolder + "/recyclarr.yaml";
      # Serve the whole YAML file
      key = "";
      # The container will also run as the same user/group
      inherit (mediaUser) uid;
      inherit (mediaUser) gid;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."recyclarr" = {
      image = "ghcr.io/recyclarr/recyclarr:8.6.0@sha256:3c38ceeb54438dd8327e4e65c9b48ba601a6d20fff833342d93c9b0bc4b1930b";
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
      user = "${mediaUser.uidStr}:${mediaUser.gidStr}";
      log-driver = "journald";
      networks = [
        "arr"
      ];
      tryRestart = false;
    };
  };
}
