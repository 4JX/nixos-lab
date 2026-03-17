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
      image = "ghcr.io/hotio/prowlarr:release-2.3.0.5236@sha256:02e472dec7a97d079f63bb9eab6799c4ca9b5e8687286e55794faa7e57944b9a";
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
