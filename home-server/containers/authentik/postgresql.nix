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
    sops.secrets.authentik-postgresql-env = secretsFile;

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."authentik-postgresql" = {
      image = "docker.io/library/postgres:16-alpine@sha256:ac55186cd25ebb254322af8daefd355d94decb6619318a4855f5635588bf4b44";
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
    };
    systemd.services = lib'.mkContainerSystemdService {
      containerName = "authentik-postgresql";
      tryRestart = true;
      networks = [
        "authentik"
      ];
    };
  };
}
