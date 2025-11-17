# https://github.com/wollomatic/socket-proxy
{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.authentik.worker;

  socketUserString = builtins.toString config.users.users.dockersocket.uid;
  dockerGroupString = builtins.toString config.users.groups.docker.gid;
in
{
  config = lib.mkIf cfg.enable {
    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."dockerproxy-authentik-worker" = {
      image = "wollomatic/socket-proxy:1.10.0@sha256:3d825f671a5a190741ad6bff645be1061bceb53eaa6517b185de869e226cb779";
      volumes = [
        "/var/run/docker.sock:/var/run/docker.sock:ro"
      ];
      cmd = [
        "-loglevel=info"
        "-allowfrom=authentik-worker"
        "-listenip=0.0.0.0"
        # https://docs.goauthentik.io/docs/add-secure-apps/outposts/integrations/docker#permissions
        # Regexes formed after a short session, probably incomplete
        # Container info may also use the container name, hence the more permissive regex for {container}/json
        # Log filter:
        # https://gchq.github.io/CyberChef/#recipe=Regular_expression('User%20defined','method%3D%5BA-Z%5D%2B%20URL%3D%22?(/v%5B0-9%5D%5C%5C.%5B0-9%5D%7B1,2%7D)?(/%5B%5C%5C.%5C%5C?a-zA-Z0-9-%3D%26%25_%5D%2B)%2B%22?',true,true,false,false,false,false,'List%20matches')Find_/_Replace(%7B'option':'Regex','string':'method%3D'%7D,'',true,false,true,false)Sort('Line%20feed',false,'Alphabetical%20(case%20sensitive)')
        "-allowGET=/(version|v1\\.[0-9]{1,2}/(info|containers/(json|[^/]+/json)|images/.*))"
        "-allowPOST=/v1\\.[0-9]{1,2}/(images/create|containers/(create|([a-f0-9]{12}|[a-f0-9]{64})/(start|kill)))"
        "-allowDELETE=/v1\\.[0-9]{1,2}/containers/([a-f0-9]{12}|[a-f0-9]{64})"
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
        "socket-proxy-authentik-worker"
      ];
      tryRestart = true;
    };
  };
}
