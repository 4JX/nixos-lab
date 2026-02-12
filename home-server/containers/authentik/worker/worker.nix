{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.authentik.worker;

  secretsFile.sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";

  authUserString = builtins.toString config.users.users.dockerauth.uid;
  authGroupString = builtins.toString config.users.groups.dockerauth.gid;
in
{
  config = lib.mkIf cfg.enable {
    sops.secrets.authentik-env = secretsFile;

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."authentik-worker" = {
      image = "ghcr.io/goauthentik/server:2025.12.4@sha256:33a92b246b798f23931ce62027e045ecf302c3bc198b6389225973db6448a886";
      environment = {
        "DOCKER_HOST" = "tcp://dockerproxy-authentik-worker:2375";
        "AUTHENTIK_REDIS__HOST" = "authentik-redis";
        "AUTHENTIK_POSTGRESQL__HOST" = "authentik-postgresql";
        "AUTHENTIK_ERROR_REPORTING__ENABLED" = "false";
        # Disable some analytics
        "AUTHENTIK_DISABLE_STARTUP_ANALYTICS" = "true";
        # AUTHENTIK_DISABLE_UPDATE_CHECK: true
      };
      environmentFiles = [
        config.sops.secrets.authentik-env.path
      ];
      volumes = [
        "/containers/authentik/authentik/certs:/certs:rw"
        "/containers/authentik/authentik/custom-templates:/templates:rw"
        "/containers/authentik/authentik/media:/media:rw"
      ];
      cmd = [ "worker" ];
      dependsOn = [
        "authentik-postgresql"
        "authentik-redis"
      ];
      user = "${authUserString}:${authGroupString}";
      log-driver = "journald";
      networks = [
        "authentik"
        "socket-proxy-authentik-worker"
      ];
      tryRestart = true;
    };
  };
}
