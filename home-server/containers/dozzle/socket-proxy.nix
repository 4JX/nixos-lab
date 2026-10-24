# https://github.com/wollomatic/socket-proxy
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.dozzle;

  socketUser = lib'.getUser "dockersocket" "dockersocket";
  dockerGroupString = builtins.toString config.users.groups.docker.gid;
in
{
  config = lib.mkIf cfg.enable {
    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."dockerproxy-dozzle" = {
      image = "wollomatic/socket-proxy:1.13.2@sha256:ff95d6ff6c27853005ef85eb8f4ab5923dc3d2f1e055f98fb6aeeaceec3fe848";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];
      cmd = [
        "-loglevel=info"
        "-allowfrom=dozzle"
        "-listenip=0.0.0.0"
        "-allowGET=/v1\\.[0-9]{1,2}/(_ping|info|events|containers/(json|([a-f0-9]{12}|[a-f0-9]{64})/(json|stats|logs)))"
        "-allowHEAD=/_ping"
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
        "socket-proxy-dozzle"
      ];
      tryRestart = true;
    };
  };
}
