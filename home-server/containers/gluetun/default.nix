# https://github.com/qdm12/gluetun
# https://github.com/qdm12/gluetun-wiki?tab=readme-ov-file#table-of-contents
{ config, lib, ... }:

let
  cfg = config.local.home-server.gluetun;
  hsCfg = config.local.home-server;
  hsEnable = hsCfg.enable;
  secretsFile.sopsFile = hsCfg.secretsFolder + "/home-server.yaml";
in
{
  options.local.home-server.gluetun.enable = lib.mkOption {
    type = lib.types.bool;
    default = hsEnable;
    description = "Whether to enable gluetun.";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.gluetun-env = secretsFile;

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."gluetun" = {
      image = "qmcgaw/gluetun:v3.40.0@sha256:2b42bfa046757145a5155acece417b65b4443c8033fb88661a8e9dcf7fda5a00";
      environmentFiles = [
        config.sops.secrets.gluetun-env.path
      ];
      ports = [
        "8888:8888/tcp"
      ];
      log-driver = "journald";
      capabilities = {
        NET_ADMIN = true;
      };
      networks = [
        "arr"
      ];
      devices = [
        "/dev/net/tun:/dev/net/tun:rwm"
      ];
    };
    systemd.services."docker-gluetun" = {
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
