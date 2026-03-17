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
      image = "amir20/dozzle:v10.5.0@sha256:bb7df69b177814466e01397f5d44baabb56dc2fe9c6f7f18b61ce137428452d2";
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
