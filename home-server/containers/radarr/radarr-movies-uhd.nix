# https://hotio.dev/containers/radarr/#starting-the-container
{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.radarr.movies-uhd;
  hsEnable = config.local.home-server.enable;

  mediaUserString = builtins.toString config.users.users.dockermedia.uid;
  mediaGroupString = builtins.toString config.users.groups.dockermedia.gid;
in
{
  options = {
    local.home-server.radarr.movies-uhd.enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable Radarr (movies-uhd).";
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
    virtualisation.oci-containers.containers."radarr-movies-uhd" = {
      image = "ghcr.io/hotio/radarr:release-6.0.4.10291@sha256:97bbe01d5e2af350c77e901c3fb529a47624beaf40b96856fa8c2ae246e6914a";
      environment = {
        "PUID" = mediaUserString;
        "PGID" = mediaGroupString;
        "UMASK" = "002";
        "TZ" = config.time.timeZone;
      };
      volumes = [
        "/containers/config/radarr-movies-uhd:/config:rw"
        "/containers/mediaserver:/data:rw"
      ];
      ports = [
        "7879:7878/tcp"
      ];
      log-driver = "journald";
      networks = [
        "arr"
      ];
      tryRestart = false;
    };
  };
}
