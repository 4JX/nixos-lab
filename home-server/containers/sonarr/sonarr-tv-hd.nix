{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.sonarr.tv-hd;
  hsEnable = config.local.home-server.enable;

  mediaUserString = builtins.toString config.users.users.dockermedia.uid;
  mediaGroupString = builtins.toString config.users.groups.dockermedia.gid;
in
{
  options = {
    local.home-server.sonarr.tv-hd.enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable Sonarr (tv-hd).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Settings:
    # https://trash-guides.info/Sonarr/Sonarr-Quality-Settings-File-Size/ -> http://localhost:8989/settings/quality (Fallback to min 5MiB/min)
    # https://trash-guides.info/Sonarr/Sonarr-recommended-naming-scheme/ -> http://localhost:8989/settings/mediamanagement (Jellyfin season folders)
    # https://trash-guides.info/Sonarr/sonarr-setup-quality-profiles/ + https://trash-guides.info/Sonarr/sonarr-setup-quality-profiles/#proper-and-repacks
    # https://trash-guides.info/Hardlinks/How-to-setup-for/ and https://trash-guides.info/Hardlinks/Examples/
    #! Disable "remove on download" for the downloaders, else chaos ensues with Hardlinks
    # To consider for movies: https://trash-guides.info/Misc/x265-4k/#golden-rule

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."sonarr-tv-hd" = {
      image = "ghcr.io/hotio/sonarr:release-4.0.16.2944@sha256:a90bf0e4d172e9920d7c97aa0ee832b6fb135452f081f7bcab83ac83a6f5d6fe";
      environment = {
        "PUID" = mediaUserString;
        "PGID" = mediaGroupString;
        "UMASK" = "002";
        "TZ" = config.time.timeZone;
      };
      volumes = [
        "/containers/config/sonarr-tv-hd:/config:rw"
        "/containers/mediaserver:/data:rw"
      ];
      ports = [
        "8989:8989/tcp"
      ];
      log-driver = "journald";
      networks = [
        "arr"
      ];
      tryRestart = false;
    };
  };
}
