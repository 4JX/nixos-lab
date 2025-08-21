{ lib, config, ... }:

let
  cfg = config.local.home-server.dozzle;

  socketUserString = builtins.toString config.users.users.dockersocket.uid;
  dockerGroupString = builtins.toString config.users.groups.docker.gid;
in
{
  config = lib.mkIf cfg.enable {
    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."dockerproxy-dozzle" = {
      image = "wollomatic/socket-proxy:1";
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
      user = "${socketUserString}:${dockerGroupString}";
      log-driver = "journald";
      extraOptions = [
        "--cap-drop=ALL"
        "--network-alias=dockerproxy-dozzle"
        "--network=socket-proxy-dozzle"
        "--security-opt=no-new-privileges"
      ];
    };
    systemd.services."docker-dockerproxy-dozzle" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
        RestartMaxDelaySec = lib.mkOverride 90 "1m";
        RestartSec = lib.mkOverride 90 "100ms";
        RestartSteps = lib.mkOverride 90 9;
      };
      after = [
        "docker-network-socket-proxy-dozzle.service"
      ];
      requires = [
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
