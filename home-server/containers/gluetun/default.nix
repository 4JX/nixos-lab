# https://github.com/qdm12/gluetun
# https://github.com/qdm12/gluetun-wiki?tab=readme-ov-file#table-of-contents
{
  config,
  lib,
  lib',
  ...
}:

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
      image = "qmcgaw/gluetun:v3.40.2@sha256:1a7b76c83640c45d75ffff8899a01df6c0baf9ad6c53999dc4fbedcd217d3c84";
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
    systemd.services = lib'.mkContainerSystemdService {
      containerName = "gluetun";
      tryRestart = false;
      networks = [
        "arr"
      ];
    };
  };
}
