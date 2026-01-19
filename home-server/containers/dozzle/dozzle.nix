# https://dozzle.dev/guide/getting-started
# PODMAN: https://github.com/amir20/dozzle?tab=readme-ov-file#installation-on-podman
{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.dozzle;

  generalUserString = builtins.toString config.users.users.dockergeneral.uid;
  generalGroupString = builtins.toString config.users.groups.dockergeneral.gid;
in
{
  config = lib.mkIf cfg.enable {
    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."dozzle" = {
      image = "amir20/dozzle:v9.0.2@sha256:bad5ccd44a1bf40492e1142e9ae6fca2c53d197a01fee5ef5d0f6ed45ea21fcb";
      environment = {
        "DOZZLE_REMOTE_HOST" = "tcp://dockerproxy-dozzle:2375";
      };
      ports = [
        "8090:8080/tcp"
      ];
      dependsOn = [
        "dockerproxy-dozzle"
      ];
      user = "${generalUserString}:${generalGroupString}";
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
