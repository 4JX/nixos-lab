# https://hotio.dev/containers/qbittorrent/#starting-the-container
{ lib, config, ... }:

let
  cfg = config.local.home-server.qbittorrent;
  hsEnable = config.local.home-server.enable;

  openFirewall = cfg.firewall.open && cfg.firewall.incomingPort != null;
  incomingPort = cfg.firewall.incomingPort;
  incomingPortString = builtins.toString incomingPort;

  mediaUser = config.users.users.dockermedia.uid;
  mediaGroup = config.users.groups.dockermedia.gid;
  mediaUserString = builtins.toString mediaUser;
  mediaGroupString = builtins.toString mediaGroup;
in
{
  options = {
    local.home-server.qbittorrent = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = hsEnable;
        description = "Whether to enable QBit.";
      };
      firewall = {
        open = lib.mkOption {
          type = lib.types.bool;
          default = false;
          description = "Whether to open the port for incoming connections inside qBit.";
        };
        # lib.types.strMatching "([0-9]{1,5}):([0-9]{1,5})/?(tcp|udp|sctp)?"
        incomingPort = lib.mkOption {
          type = lib.types.nullOr lib.types.int;
          default = null;
          description = "The port used for incoming connections inside qBit.";
        };
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.qbit-wg0 = {
      sopsFile = config.local.home-server.secretsFolder + "/qbit-wg0.conf";
      format = "binary";
      uid = mediaUser;
      gid = mediaGroup;
    };

    # Open up a port for qbittorrent
    networking.firewall = lib.mkIf openFirewall {
      allowedTCPPorts = [ incomingPort ];
      allowedUDPPorts = [ incomingPort ];
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."qbittorrent" = {
      # image = "ghcr.io/hotio/qbittorrent:release-5.0.2";
      image = "ghcr.io/hotio/qbittorrent:release-4.6.7";
      environment = {
        "PUID" = mediaUserString;
        "PGID" = mediaGroupString;
        "UMASK" = "002";

        "TZ" = config.time.timeZone;
        "WEBUI_PORTS" = "8080/tcp,8080/udp"; # Expose WebUI

        # VPN Config
        # https://hotio.dev/containers/qbittorrent/#wireguard
        "VPN_CONF" = "wg0";
        "VPN_ENABLED" = "true";
        # https://protonvpn.com/vpn-servers
        "VPN_PROVIDER" = "proton";
        "VPN_LAN_NETWORK" = "192.168.1.0/24";
        "VPN_LAN_LEAK_ENABLED" = "false";
        "VPN_EXPOSE_PORTS_ON_LAN" = "8080/tcp";
        "VPN_AUTO_PORT_FORWARD" = "true";
        "VPN_AUTO_PORT_FORWARD_TO_PORTS" = "";
        "VPN_KEEP_LOCAL_DNS" = "false";
        "VPN_FIREWALL_TYPE" = "auto";
        "VPN_HEALTHCHECK_ENABLED" = "false";

        "PRIVOXY_ENABLED" = "true";
        "UNBOUND_ENABLED" = "false";
      };
      volumes = [
        "/containers/config/qbittorrent:/config:rw"
        "${config.sops.secrets.qbit-wg0.path}:/config/wireguard/wg0.conf:rw"
        "/containers/mediaserver/torrents:/data/torrents:rw"
      ];
      ports = [
        "8080:8080/tcp"
        "8118:8118/tcp"
      ]
      ++ lib.optionals openFirewall [
        "${incomingPortString}:${incomingPortString}/tcp"
      ];
      log-driver = "journald";
      capabilities = {
        NET_ADMIN = true;
      };
      extraOptions = [
        "--dns=1.1.1.1"
        "--dns=9.9.9.9"
        "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
        "--sysctl=net.ipv6.conf.all.disable_ipv6=1"
      ];
      networks = [
        "arr"
      ];
    };

    systemd.services."docker-qbittorrent" = {
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
