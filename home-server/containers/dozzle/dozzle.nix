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
      image = "amir20/dozzle:v9.0.3@sha256:2d59d09503f2c947133a4f231fdeb1f4c99e23aa0d4137f81bb1a6318e0e06cf";
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
