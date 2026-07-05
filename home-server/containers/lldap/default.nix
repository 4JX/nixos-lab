# https://github.com/lldap/lldap
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.lldap;
  hsCfg = config.local.home-server;
  hsEnable = hsCfg.enable;
  secretsFile.sopsFile = hsCfg.secretsFolder + "/home-server.yaml";

  authUser = lib'.getUser "dockerauth" "dockerauth";
in
{
  options.local.home-server.lldap.enable = lib.mkOption {
    type = lib.types.bool;
    default = hsEnable;
    description = "Whether to enable LLDAP.";
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib'.mkContainerSecret {
      containerName = "lldap";
      secretName = "lldap-env";
      inherit (secretsFile) sopsFile;
    };

    virtualisation.oci-containers.containers."lldap" = {
      image = "lldap/lldap:2026-05-26-alpine-rootless@sha256:c8cf0436c1f8e75307bd24887fcca4316fc08910fc9b693b4dd9f56fb729d1d0";
      environment = {
        "LLDAP_DATABASE_URL" = "sqlite:///data/users.db?mode=rwc";
      };
      environmentFiles = [
        config.sops.secrets.lldap-env.path
      ];
      volumes = [
        "/containers/auth/lldap:/data:rw"
      ];
      ports = [
        "17170:17170/tcp"
      ];
      user = "${authUser.uidStr}:${authUser.gidStr}";
      log-driver = "journald";
      networks = [
        "ldap"
        "lldap"
      ];
      tryRestart = true;
    };
  };
}
