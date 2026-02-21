# https://github.com/wollomatic/socket-proxy
{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.beszel;

  socketUserString = builtins.toString config.users.users.dockersocket.uid;
  dockerGroupString = builtins.toString config.users.groups.docker.gid;
in
{
  config = lib.mkIf cfg.enable {
    # TODO: Template generate docker proxy containers as container options
    # TODO: Maybe specify user and group separately in a special arg to handle secrets as well
    virtualisation.oci-containers.containers."dockerproxy-beszel" = {
      image = "wollomatic/socket-proxy:1.11.3@sha256:9ecd9363c5b290b27c9d77f3fae812073713f528a401fe01fe2919520b9081d0";
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
      user = "${socketUserString}:${dockerGroupString}";
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
