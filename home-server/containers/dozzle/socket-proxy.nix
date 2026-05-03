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
      image = "wollomatic/socket-proxy:1.12.0@sha256:a522d93fc041d15e79ce3179ffbfb74ceb3ca417133f74bb0ae3c0386bd103ca";
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
