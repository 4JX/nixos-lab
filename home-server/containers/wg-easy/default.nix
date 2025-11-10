# https://github.com/wg-easy/wg-easy
# sudo docker run --rm -it ghcr.io/wg-easy/wg-easy wgpw 'password'
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
  secretsFile.sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";
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
    sops.secrets.wg-easy-env = secretsFile;

    # networking.firewall = {
    #   allowedUDPPorts = [ cfg.serverPort ];
    # };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."wg-easy" = {
      image = "ghcr.io/wg-easy/wg-easy:15@sha256:bb8152762c36f824eb42bb2f3c5ab8ad952818fbef677d584bc69ec513b251b0";
      environmentFiles = [
        config.sops.secrets.wg-easy-env.path
      ];
      volumes = [
        "/containers/config/wg-easy:/etc/wireguard:rw"
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
      };
      extraOptions = [
        "--sysctl=net.ipv4.conf.all.src_valid_mark=1"
        "--sysctl=net.ipv4.ip_forward=1"
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
