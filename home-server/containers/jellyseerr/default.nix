# https://docs.jellyseerr.dev/
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.jellyseerr;
  hsEnable = config.local.home-server.enable;

  openFirewall = cfg.firewall.open && cfg.firewall.port != null;
  inherit (cfg.firewall) port;
  portString = builtins.toString port;

  mediaUserString = builtins.toString config.users.users.dockermedia.uid;
  mediaGroupString = builtins.toString config.users.groups.dockermedia.gid;
in
{
  options = {
    local.home-server.jellyseerr = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = hsEnable;
        description = "Whether to enable Jellyseerr.";
      };
      firewall = {
        open = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to open the port for incoming connections inside Jellyseerr.";
        };
        port = lib.mkOption {
          type = lib.types.int;
          default = 5055;
          description = "The port used for connections inside Jellyseerr.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall = lib.mkIf openFirewall {
      allowedTCPPorts = [ port ];
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."jellyseerr" = {
      image = "fallenbagel/jellyseerr:2.7.3@sha256:4538137bc5af902dece165f2bf73776d9cf4eafb6dd714670724af8f3eb77764";
      environment = {
        "LOG_LEVEL" = "debug";
        "TZ" = config.time.timeZone;
      };
      volumes = [
        "/containers/config/jellyseerr:/app/config:rw"
      ];
      ports = [
        "${portString}:5055/tcp"
      ];
      user = "${mediaUserString}:${mediaGroupString}";
      log-driver = "journald";
      networks = [
        "arr"
        "exposed"
      ];
    };
    systemd.services = lib'.mkContainerSystemdService {
      containerName = "jellyseerr";
      tryRestart = false;
      networks = [
        "arr"
        "exposed"
      ];
    };
  };
}
