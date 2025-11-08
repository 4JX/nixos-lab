{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.dnsmasq;
  hsEnable = config.local.home-server.enable;

  wgPortString = builtins.toString cfg.wgPort;
in
{
  options = {
    local.home-server.dnsmasq = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = hsEnable;
        description = "Whether to enable dnsmasq.";
      };
      wgPort = lib.mkOption {
        type = lib.types.int;
        default = 54000;
        description = "The port used for connections inside wg-easy.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [ cfg.wgPort ];

    # Configure networks
    local.home-server.containers.networks = [
      # HACK: Create a custom network for the wireguard server because for some reason other network subnets
      # become unreachable if the container is just assigned to the existing networks where containers already exist.
      # Use "0" as a prefix to have it get chosen as the one to get an IP from by docker.
      { name = "0wireguard"; }
    ];

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."dnsmasq" = {
      image = "4km3/dnsmasq:2.90-r3@sha256:038fa882bdae13d4a93155df2d865ed744a02f34f09631e140a3b91c5b16c54c";
      volumes = [
        "/containers/config/dnsmasq/dnsmasq.conf:/etc/dnsmasq.conf:ro"
      ];
      ports = [
        "5300:53/tcp"
        "5300:53/udp"
        "${wgPortString}:51820/udp"
        "54001:51821/tcp"
      ];
      log-driver = "journald";
      capabilities = {
        NET_ADMIN = true;
      };
      networks = [
        "0wireguard"
      ];
    };
    systemd.services = lib'.mkContainerSystemdService {
      containerName = "dnsmasq";
      tryRestart = false;
      networks = [
        "0wireguard"
      ];
    };
  };
}
