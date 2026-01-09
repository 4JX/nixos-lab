{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.sonarr.tv-uhd;
  hsEnable = config.local.home-server.enable;

  mediaUserString = builtins.toString config.users.users.dockermedia.uid;
  mediaGroupString = builtins.toString config.users.groups.dockermedia.gid;
in
{
  options = {
    local.home-server.sonarr.tv-uhd.enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable Sonarr (tv-uhd).";
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
    virtualisation.oci-containers.containers."sonarr-tv-uhd" = {
      image = "ghcr.io/hotio/sonarr:release-4.0.16.2944@sha256:787f242ebc20d4c6e28c599c1d1187a047469b1fe2c743816e560fc9158b1a77";
      environment = {
        "PUID" = mediaUserString;
        "PGID" = mediaGroupString;
        "UMASK" = "002";
        "TZ" = config.time.timeZone;
      };
      volumes = [
        "/containers/config/sonarr-tv-uhd:/config:rw"
        "/containers/mediaserver:/data:rw"
      ];
      ports = [
        "8990:8989/tcp"
      ];
      log-driver = "journald";
      networks = [
        "arr"
      ];
      tryRestart = false;
    };
  };
}
