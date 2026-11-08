# https://hotio.dev/containers/prowlarr/#starting-the-container
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.prowlarr;
  hsEnable = config.local.home-server.enable;

  mediaUser = lib'.getUser "dockermedia" "dockermedia";
in
{
  options = {
    local.home-server.prowlarr = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = hsEnable;
        description = "Whether to enable Prowlarr.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."prowlarr" = {
      image = "ghcr.io/hotio/prowlarr:release-2.7.0.5723@sha256:50ccdde38e1ad0834cc05b7eae54e9734ac6af76a1780b99066dd18d37b9802d";
      environment = {
        "PUID" = mediaUser.uidStr;
        "PGID" = mediaUser.gidStr;
        "UMASK" = "002";
        "TZ" = config.time.timeZone;
      };
      volumes = [
        "/containers/config/prowlarr:/config:rw"
      ];
      ports = [
        "9696:9696/tcp"
      ];
      log-driver = "journald";
      networks = [
        "arr"
      ];
      tryRestart = false;
    };
  };
}
