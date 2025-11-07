# https://hotio.dev/containers/jellyfin/
# Migration: Compare paths in
# https://jellyfin.org/docs/general/administration/migrate/#migrating-linux-install-to-docker
# https://hotio.dev/containers/jellyfin/#configuration
# https://github.com/NixOS/nixpkgs/blob/40916ded4ad5fe4bcc18963217c3a026db505c7f/nixos/modules/services/misc/jellyfin.nix#L27-L63
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
        "PUID" = mediaUserString;
        "PGID" = mediaGroupString;
        "UMASK" = "002";
        "TZ" = config.time.timeZone;
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
        # https://jellyfin.org/docs/general/installation/container#with-hardware-acceleration
        # Needed for hardware acceleration/transcoding
        "--device=/dev/dri:/dev/dri:rwm"
        "--network-alias=jellyfin"
        "--network=arr"
        "--network=exposed"
        "--network=ldap"
      ]
      ++ lib.optionals containerToolkitEnable [
        # https://jellyfin.org/docs/general/installation/container#with-hardware-acceleration
        # Needed for hardware acceleration/transcoding
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
