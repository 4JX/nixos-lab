{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.authentik.worker;

  secretsFile.sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";

  authUser = lib'.getUser "dockerauth" "dockerauth";
in
{
  config = lib.mkIf cfg.enable {
    sops.secrets = lib'.mkContainerSecret {
      containerName = "authentik-worker";
      secretName = "authentik-env";
      restartUnits = [
        (lib'.mkContainerServiceName "authentik-server")
      ];
      inherit (secretsFile) sopsFile;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."authentik-worker" = {
      image = "ghcr.io/goauthentik/server:2026.8.3@sha256:ab9b4e8cc4ab3f8d1198d2db6aeea66bafea1963b3f2843589e0d163f97d9849";
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
      user = "${authUser.uidStr}:${authUser.gidStr}";
      log-driver = "journald";
      networks = [
        "authentik"
        "socket-proxy-authentik-worker"
      ];
      tryRestart = true;
    };
  };
}
