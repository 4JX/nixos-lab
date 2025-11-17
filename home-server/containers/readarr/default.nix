# https://readarr.com/
{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.readarr;
  hsEnable = config.local.home-server.enable;

  mediaUserString = builtins.toString config.users.users.dockermedia.uid;
  mediaGroupString = builtins.toString config.users.groups.dockermedia.gid;
in
{
  options = {
    local.home-server.readarr.enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable Readarr.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."readarr" = {
      image = "ghcr.io/hotio/readarr:testing-0.4.18.2805@sha256:91e3d1c9e0dbc6f4ece5ae9f9f7ed3ca4ed4fdeff241b95c49337ba38c91da72";
      environment = {
        "PUID" = mediaUserString;
        "PGID" = mediaGroupString;
        "UMASK" = "002";
        "TZ" = "Etc/UTC";
      };
      volumes = [
        "/containers/config/readarr:/config:rw"
        "/containers/mediaserver:/data:rw"
      ];
      ports = [
        "8787:8787/tcp"
      ];
      log-driver = "journald";
      networks = [
        "arr"
      ];
      tryRestart = false;
    };
  };
}
