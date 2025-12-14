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
      image = "amir20/dozzle:v8.14.12@sha256:0df89c904da71e94a0c9ed3c89a890f01488321b5f10ac1e0c0bedcead9af6e4";
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
