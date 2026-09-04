# https://dozzle.dev/guide/getting-started
# PODMAN: https://github.com/amir20/dozzle?tab=readme-ov-file#installation-on-podman
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.dozzle;

  generalUser = lib'.getUser "dockergeneral" "dockergeneral";
in
{
  config = lib.mkIf cfg.enable {
    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."dozzle" = {
      image = "amir20/dozzle:v10.9.2@sha256:1124fe771e2d31e18db8064e93e7eb24d436f92634abdedeca47cb4eb2c9b991";
      environment = {
        "DOZZLE_REMOTE_HOST" = "tcp://dockerproxy-dozzle:2375";
      };
      ports = [
        "8090:8080/tcp"
      ];
      dependsOn = [
        "dockerproxy-dozzle"
      ];
      user = "${generalUser.uidStr}:${generalUser.gidStr}";
      log-driver = "journald";
      capabilities = {
        ALL = false;
      };
      extraOptions = [
        "--security-opt=no-new-privileges"
      ];
      networks = [
        "dozzle"
        "socket-proxy-dozzle"
      ];
      tryRestart = false;
    };
  };
}
