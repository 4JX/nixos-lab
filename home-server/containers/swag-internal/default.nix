# https://docs.linuxserver.io/general/swag/#swag
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.swag-internal;
  hsEnable = config.local.home-server.enable;

  proxyUser = lib'.getUser "dockerproxy" "dockerproxy";
in
{
  options.local.home-server.swag-internal = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable SWAG-Internal.";
    };
    containerIp = lib.mkOption {
      type = lib.types.str;
      default = "172.31.254.2";
      description = "The fixed IP address for swag-internal on the 0wireguard network.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib'.mkContainerSecret {
      containerName = "swag-internal";
      secretName = "swag-internal-env";
      sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";
      inherit (proxyUser) uid;
      inherit (proxyUser) gid;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."swag-internal" = {
      image = "lscr.io/linuxserver/swag:5.6.0@sha256:d775eb8598d7918296b7c547a1dff7cc59f972f099e3f29682d8bd393d8e2e1b";
      environment = {
        "PUID" = proxyUser.uidStr;
        "PGID" = proxyUser.gidStr;
        "TZ" = config.time.timeZone;
        # - URL=
        "SUBDOMAINS" = "wildcard";
        "VALIDATION" = "dns";
        "CERTPROVIDER" = "";
        "DNSPLUGIN" = "cloudflare";
        # - EMAIL=
        "ONLY_SUBDOMAINS" = "false";
        "EXTRA_DOMAINS" = "";
        "STAGING" = "false";
        "SWAG_AUTORELOAD" = "true";
        "DOCKER_MODS" = "";
      };
      environmentFiles = [
        config.sops.secrets.swag-internal-env.path
      ];
      volumes = [
        "/containers/config/swag-internal:/config:rw"
      ];
      log-driver = "journald";
      capabilities = {
        NET_ADMIN = true;
      };
      extraOptions = [
        "--ip=${cfg.containerIp}"
      ];
      networks = [
        "0wireguard"
        "arr"
        "beszel"
        "dozzle"
        "exposed"
        "komga"
        "lldap"
        "thelounge"
      ];
      tryRestart = false;
    };
  };
}
