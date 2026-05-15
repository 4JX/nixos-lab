{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.authentik.postgresql;
  hsEnable = config.local.home-server.enable;
  authentikEnable = config.local.home-server.authentik.enable;

  secretsFile.sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";
in
{
  options = {
    local.home-server.authentik.postgresql.enable = lib.mkOption {
      type = lib.types.bool;
      default = authentikEnable && hsEnable;
      description = "Whether to enable the Authentik postgresql database.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib'.mkContainerSecret {
      containerName = "authentik-postgresql";
      secretName = "authentik-postgresql-env";
      inherit (secretsFile) sopsFile;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."authentik-postgresql" = {
      image = "docker.io/library/postgres:16-alpine@sha256:890480b08124ce7f79960a9bb16fe39729aa302bd384bfd7c408fee6c8f7adb7";
      environmentFiles = [
        config.sops.secrets.authentik-postgresql-env.path
      ];
      volumes = [
        "/containers/authentik/postgresql:/var/lib/postgresql/data:rw"
      ];
      log-driver = "journald";
      extraOptions = [
        "--health-cmd=pg_isready -d \${POSTGRES_DB} -U \${POSTGRES_USER}"
        "--health-interval=30s"
        "--health-retries=5"
        "--health-start-period=20s"
        "--health-timeout=5s"
      ];
      networks = [
        "authentik"
      ];
      tryRestart = true;
    };
  };
}
