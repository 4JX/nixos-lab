# https://hotio.dev/containers/radarr/#starting-the-container
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.radarr.movies-hd;
  hsEnable = config.local.home-server.enable;

  mediaUser = lib'.getUser "dockermedia" "dockermedia";
in
{
  options = {
    local.home-server.radarr.movies-hd.enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable Radarr (movies-hd).";
    };
  };

  config = lib.mkIf cfg.enable {
    # Settings:
    # https://trash-guides.info/Radarr/Radarr-Quality-Settings-File-Size/ -> http://localhost:7878/settings/quality (Fallback to min 5MiB/min)
    # https://trash-guides.info/Radarr/Radarr-recommended-naming-scheme/ -> http://localhost:7878/settings/mediamanagement (Jellyfin season folders)
    # https://trash-guides.info/Radarr/radarr-setup-quality-profiles/ + https://trash-guides.info/Radarr/radarr-setup-quality-profiles/#proper-and-repacks
    # https://trash-guides.info/Hardlinks/How-to-setup-for/ and https://trash-guides.info/Hardlinks/Examples/
    #! Disable "remove on download" for the downloaders, else chaos ensues with Hardlinks
    # To consider for movies: https://trash-guides.info/Misc/x265-4k/#golden-rule

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."radarr-movies-hd" = {
      image = "ghcr.io/hotio/radarr:release-6.1.1.10360@sha256:a0378fd5be0d23e23eea5f183e12619d2c1d74f70e5dc4a124c315343595f2ae";
      environment = {
        "PUID" = mediaUser.uidStr;
        "PGID" = mediaUser.gidStr;
        "UMASK" = "002";
        "TZ" = config.time.timeZone;
      };
      volumes = [
        "/containers/config/radarr-movies-hd:/config:rw"
        "/containers/mediaserver:/data:rw"
      ];
      ports = [
        "7878:7878/tcp"
      ];
      log-driver = "journald";
      networks = [
        "arr"
      ];
      tryRestart = false;
    };
  };
}
