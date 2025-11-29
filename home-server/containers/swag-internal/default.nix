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
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.swag-internal-env = {
      sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";
      uid = proxyUser;
      gid = proxyGroup;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."swag-internal" = {
      image = "lscr.io/linuxserver/swag:5.1.0@sha256:c618d7be86c61924355299048d169412c2ebc4fb4489b9d2e3064f9574acd4cb";
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
      ports = [
        "4433:443/tcp"
        "800:80/tcp"
      ];
      log-driver = "journald";
      capabilities = {
        NET_ADMIN = true;
      };
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
