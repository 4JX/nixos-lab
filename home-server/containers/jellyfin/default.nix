{ lib, config, ... }:

let
  cfg = config.local.home-server.jellyfin;
  hsEnable = config.local.home-server.enable;
  containerToolkitEnable = config.local.home-server.nvidia-container-toolkit.enable;

  openFirewall = cfg.firewall.open && cfg.firewall.port != null;
  port = cfg.firewall.port;
  portString = builtins.toString port;

  mediaUserString = builtins.toString config.users.users.dockermedia.uid;
  mediaGroupString = builtins.toString config.users.groups.dockermedia.gid;
in
{
  options = {
    local.home-server.jellyfin = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = hsEnable;
        description = "Whether to enable Jellyfin.";
      };
      firewall = {
        open = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to open the port for incoming connections inside Jellyfin.";
        };
        port = lib.mkOption {
          type = lib.types.int;
          default = 8096;
          description = "The port used for connections inside Jellyfin.";
        };
      };

    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = lib.mkIf openFirewall {
      allowedTCPPorts = [ port ];
    };

    virtualisation.oci-containers.containers."jellyfin" = {
      image = "ghcr.io/hotio/jellyfin";
      environment = {
        "PGID" = mediaGroupString;
        "PUID" = mediaUserString;
        "TZ" = config.time.timeZone;
        "UMASK" = "002";
      };
      volumes = [
        "/containers/config/jellyfin:/config:rw"
        "/containers/mediaserver/media:/data/media:ro"
      ];
      ports = [
        "${portString}:8096/tcp"
      ];
      log-driver = "journald";
      extraOptions = [
        "--device=/dev/dri:/dev/dri:rwm"
        "--network-alias=jellyfin"
        "--network=arr"
        "--network=exposed"
        "--network=ldap"
      ]
      ++ lib.optionals containerToolkitEnable [
        "--device=nvidia.com/gpu=all"
      ];
    };
    systemd.services."docker-jellyfin" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "no";
      };
      after = [
        "docker-network-arr.service"
        "docker-network-exposed.service"
      ];
      requires = [
        "docker-network-arr.service"
        "docker-network-exposed.service"
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
