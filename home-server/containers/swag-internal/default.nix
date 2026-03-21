# https://docs.linuxserver.io/general/swag/#swag
{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.swag-internal;
  hsEnable = config.local.home-server.enable;

  proxyUser = config.users.users.dockerproxy.uid;
  proxyGroup = config.users.groups.dockerproxy.gid;
  proxyUserString = builtins.toString proxyUser;
  proxyGroupString = builtins.toString proxyGroup;
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
    sops.secrets.swag-internal-env = {
      sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";
      uid = proxyUser;
      gid = proxyGroup;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."swag-internal" = {
      image = "lscr.io/linuxserver/swag:5.4.0@sha256:97d43849e25c3d97ee0a1c406b5ba894242f8375685c6075803e1a178d441767";
      environment = {
        "PUID" = proxyUserString;
        "PGID" = proxyGroupString;
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
        "thelounge"
      ];
      tryRestart = false;
    };
  };
}
