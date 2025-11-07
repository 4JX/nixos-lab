{ lib, config, ... }:

let
  cfg = config.local.home-server.authentik.server;
  hsEnable = config.local.home-server.enable;
  authentikEnable = config.local.home-server.authentik.enable;

  secretsFile.sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";
in
{
  options = {
    local.home-server.authentik.server.enable = lib.mkOption {
      type = lib.types.bool;
      default = authentikEnable && hsEnable;
      description = "Whether to enable the Authentik server.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.authentik-env = secretsFile;

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."authentik-server" = {
      image = "ghcr.io/goauthentik/server:2024.10.5";
      environment = {
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
        "/containers/authentik/authentik/media:/media:rw"
        "/containers/authentik/authentik/custom-templates:/templates:rw"
      ];
      ports = [
        "9000:9000/tcp"
        "9443:9443/tcp"
      ];
      cmd = [ "server" ];
      dependsOn = [
        "authentik-postgresql"
        "authentik-redis"
      ];
      log-driver = "journald";
      networks = [
        "authentik"
        "exposed"
        "ldap"
      ];
    };
    systemd.services."docker-authentik-server" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
        RestartMaxDelaySec = lib.mkOverride 90 "1m";
        RestartSec = lib.mkOverride 90 "100ms";
        RestartSteps = lib.mkOverride 90 9;
      };
      after = [
        "docker-network-authentik.service"
        "docker-network-ldap.service"
      ];
      requires = [
        "docker-network-authentik.service"
        "docker-network-ldap.service"
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
