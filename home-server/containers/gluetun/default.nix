# https://github.com/qdm12/gluetun
# https://github.com/qdm12/gluetun-wiki?tab=readme-ov-file#table-of-contents
{
  config,
  lib,
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
      image = "qmcgaw/gluetun:v3.41.1@sha256:1a5bf4b4820a879cdf8d93d7ef0d2d963af56670c9ebff8981860b6804ebc8ab";
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
      tryRestart = false;
    };
  };
}
