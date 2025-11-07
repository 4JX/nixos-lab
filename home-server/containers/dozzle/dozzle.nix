# https://dozzle.dev/guide/getting-started
# PODMAN: https://github.com/amir20/dozzle?tab=readme-ov-file#installation-on-podman
{ lib, config, ... }:

let
  cfg = config.local.home-server.dozzle;

  generalUserString = builtins.toString config.users.users.dockergeneral.uid;
  generalGroupString = builtins.toString config.users.groups.dockergeneral.gid;
in
{
  config = lib.mkIf cfg.enable {
    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."dozzle" = {
      image = "amir20/dozzle:v8";
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
      extraOptions = [
        "--cap-drop=ALL"
        "--network-alias=dozzle"
        "--network=dozzle"
        "--network=socket-proxy-dozzle"
        "--security-opt=no-new-privileges"
      ];
    };
    systemd.services."docker-dozzle" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "no";
      };
      after = [
        "docker-network-dozzle.service"
        "docker-network-socket-proxy-dozzle.service"
      ];
      requires = [
        "docker-network-dozzle.service"
        "docker-network-socket-proxy-dozzle.service"
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
