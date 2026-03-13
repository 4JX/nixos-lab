# https://github.com/wg-easy/wg-easy
{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.wg-easy;
  hsEnable = config.local.home-server.enable;

  listenPortString = builtins.toString cfg.listenPort;
in
{
  options.local.home-server.wg-easy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable wg-easy";
    };
    listenPort = lib.mkOption {
      type = lib.types.int;
      default = 54000;
      description = "The host port used for WireGuard connections.";
    };
  };

  config = lib.mkIf cfg.enable {
    networking.firewall.allowedUDPPorts = [ cfg.listenPort ];

    # Configure networks
    virtualisation.oci-containers.networks = [
      {
        # HACK: Create a custom network for the wireguard server because for some reason other network subnets
        # become unreachable if the container is just assigned to the existing networks where containers already exist.
        # Use "0" as a prefix to have it get chosen as the one to get an IP from by docker.
        name = "0wireguard";
        subnet = "172.31.254.0/24";
        ipRange = "172.31.254.128/25";
        gateway = "172.31.254.1";
      }
    ];

    # https://wg-easy.github.io/wg-easy/v15.0/faq/#cant-initialize-ip6tables-table-nat-table-does-not-exist-do-you-need-to-insmod
    #! Use nftables:
    # https://github.com/wg-easy/wg-easy/issues/2220
    # https://wg-easy.github.io/wg-easy/Pre-release/examples/tutorials/podman-nft/#load-kernel-modules
    boot.kernelModules = [
      "wireguard"
      "nft_masq"
    ];

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."wg-easy" = {
      image = "ghcr.io/wg-easy/wg-easy:15.2.2@sha256:cf815209439101842f81d62bb25f7d66140e4cf8c100b4de5d0e84569d38732a";
      environment = {
        # https://wg-easy.github.io/wg-easy/latest/advanced/config/optional-config/
        #  - PORT=51821
        #  - HOST=0.0.0.0
        #  - INSECURE=false
        "INSECURE" = "false";
        "DISABLE_IPV6" = "true";
      };
      volumes = [
        "/containers/config/wg-easy:/etc/wireguard:rw"
        # - /lib/modules:/lib/modules:ro
        # See: https://github.com/wg-easy/wg-easy/issues/1919#issuecomment-3318257458
        # "/run/current-system/kernel-modules/lib/modules:/lib/modules:ro"
      ];
      ports = [
        "${listenPortString}:51820/udp"
        "54001:51821/tcp"
      ];
      dependsOn = [
        "blocky"
      ];
      log-driver = "journald";
      capabilities = {
        NET_ADMIN = true;
        SYS_MODULE = true;
        # - NET_RAW # Uncomment if using Podman
      };
      extraOptions = [
        "--sysctl=net.ipv4.ip_forward=1"
        "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
        "--sysctl=net.ipv6.conf.all.disable_ipv6=0"
        "--sysctl=net.ipv6.conf.all.forwarding=1"
        "--sysctl=net.ipv6.conf.default.forwarding=1"
      ];
      networks = [
        "0wireguard"
      ];
      tryRestart = true;
    };
  };
}
