# https://github.com/wg-easy/wg-easy
# Ports are handled in dnsmasq
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.wg-easy;
  hsEnable = config.local.home-server.enable;

  # serverPortString = builtins.toString cfg.serverPort;
in
{
  options.local.home-server.wg-easy = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable wg-easy";
    };
    # serverPort = lib.mkOption {
    #   type = lib.types.int;
    #   default = 54000;
    #   description = "The port used for connections inside wg-easy.";
    # };
  };

  config = lib.mkIf cfg.enable {
    # networking.firewall = {
    #   allowedUDPPorts = [ cfg.serverPort ];
    # };

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
      image = "ghcr.io/wg-easy/wg-easy:15.1.0@sha256:bb8152762c36f824eb42bb2f3c5ab8ad952818fbef677d584bc69ec513b251b0";
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
      # ports = [
      #   "${serverPortString}:51820/udp"
      #   "54001:51821/tcp"
      # ];
      dependsOn = [
        "dnsmasq"
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
        "container:dnsmasq"
      ];
    };
    systemd.services = lib'.mkContainerSystemdService {
      containerName = "wg-easy";
      tryRestart = true;
      networks = [ ];
    };
  };
}
