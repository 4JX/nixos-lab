# https://hotio.dev/containers/jellyfin/
# Migration: Compare paths in
# https://jellyfin.org/docs/general/administration/migrate/#migrating-linux-install-to-docker
# https://hotio.dev/containers/jellyfin/#configuration
# https://github.com/NixOS/nixpkgs/blob/40916ded4ad5fe4bcc18963217c3a026db505c7f/nixos/modules/services/misc/jellyfin.nix#L27-L63
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.jellyfin;
  hsEnable = config.local.home-server.enable;
  containerToolkitEnable = config.local.home-server.nvidia-container-toolkit.enable;

  openFirewall = cfg.firewall.open && cfg.firewall.port != null;
  inherit (cfg.firewall) port;
  portString = builtins.toString port;

  mediaUser = lib'.getUser "dockermedia" "dockermedia";
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
      image = "ghcr.io/hotio/jellyfin:release-10.11.11@sha256:b3436c4c8f9331c1bdfd8adcb8706f8dcf8410e1c55dc7e23d7e88e5023ae8e2";
      environment = {
        "PUID" = mediaUser.uidStr;
        "PGID" = mediaUser.gidStr;
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
      networks = [
        "arr"
        "exposed"
        "ldap"
      ];
      # https://jellyfin.org/docs/general/installation/container#with-hardware-acceleration
      # Needed for hardware acceleration/transcoding
      devices = [
        "/dev/dri:/dev/dri:rwm"
      ]
      ++ lib.optionals containerToolkitEnable [
        "nvidia.com/gpu=all"
      ];
      tryRestart = false;
    };
  };
}
