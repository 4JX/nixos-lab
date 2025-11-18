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
      image = "wollomatic/socket-proxy:1.10.0@sha256:3d825f671a5a190741ad6bff645be1061bceb53eaa6517b185de869e226cb779";
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
