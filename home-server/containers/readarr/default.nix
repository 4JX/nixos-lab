{ lib, config, ... }:

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
      image = "ghcr.io/hotio/readarr";
      environment = {
        "PGID" = mediaGroupString;
        "PUID" = mediaUserString;
        "TZ" = "Etc/UTC";
        "UMASK" = "002";
      };
      volumes = [
        "/containers/config/readarr:/config:rw"
        "/containers/mediaserver:/data:rw"
      ];
      ports = [
        "8787:8787/tcp"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=readarr"
        "--network=arr"
      ];
    };
    systemd.services."docker-readarr" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "no";
      };
      after = [
        "docker-network-arr.service"
      ];
      requires = [
        "docker-network-arr.service"
      ];
      partOf = [
        "docker-compose-home-server-root.target"
      ];
      wantedBy = [
        "docker-compose-home-server-root.target"
      ];
    };
  };
}
