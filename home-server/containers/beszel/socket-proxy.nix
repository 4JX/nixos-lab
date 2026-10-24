# https://github.com/wollomatic/socket-proxy
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.beszel;

  socketUser = lib'.getUser "dockersocket" "dockersocket";
  dockerGroupString = builtins.toString config.users.groups.docker.gid;
in
{
  config = lib.mkIf cfg.enable {
    # TODO: Template generate docker proxy containers as container options
    virtualisation.oci-containers.containers."dockerproxy-beszel" = {
      image = "wollomatic/socket-proxy:1.13.2@sha256:ff95d6ff6c27853005ef85eb8f4ab5923dc3d2f1e055f98fb6aeeaceec3fe848";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];
      cmd = [
        "-loglevel=info"
        "-allowfrom=beszel-agent"
        "-listenip=0.0.0.0"
        "-allowGET=/version|/containers/(json|([a-f0-9]{12}|[a-f0-9]{64})/(json|stats|logs))"
        "-watchdoginterval=300"
        "-stoponwatchdog"
        "-shutdowngracetime=10"
      ];
      user = "${socketUser.uidStr}:${dockerGroupString}";
      log-driver = "journald";
      capabilities = {
        ALL = false;
      };
      extraOptions = [
        "--security-opt=no-new-privileges"
      ];
      networks = [
        "socket-proxy-beszel"
      ];
      tryRestart = true;
    };
  };
}
