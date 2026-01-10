# https://docs.linuxserver.io/general/swag/#swag
# https://github.com/linuxserver/reverse-proxy-confs?tab=readme-ov-file#how-to-use-these-reverse-proxy-configs
# https://www.linuxserver.io/blog/zero-trust-hosting-and-reverse-proxy-via-cloudflare-swag-and-authelia
{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.swag;
  hsEnable = config.local.home-server.enable;

  proxyUser = config.users.users.dockerproxy.uid;
  proxyGroup = config.users.groups.dockerproxy.gid;
  proxyUserString = builtins.toString proxyUser;
  proxyGroupString = builtins.toString proxyGroup;
in
{
  options.local.home-server.swag = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable SWAG.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.swag-env = {
      sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";
      uid = proxyUser;
      gid = proxyGroup;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."swag" = {
      image = "lscr.io/linuxserver/swag:5.2.2@sha256:fc3a771c18cfd4f7f207ee6b6e51b66beb0a72c333fcf244cc6df91015f04d23";
      environment = {
        "PUID" = proxyUserString;
        "PGID" = proxyGroupString;
        "TZ" = config.time.timeZone;
        # - URL=
        "SUBDOMAINS" = "wildcard";
        "CERTPROVIDER" = "";
        "VALIDATION" = "dns";
        "DNSPLUGIN" = "cloudflare";
        # - EMAIL=
        "ONLY_SUBDOMAINS" = "false";
        "EXTRA_DOMAINS" = "";
        "STAGING" = "false";
        "SWAG_AUTORELOAD" = "true";
        # https://github.com/linuxserver/docker-mods/tree/swag-cloudflare-real-ip
        # Real IP works with a separate container, no need for the cloudflared mod
        "DOCKER_MODS" = "linuxserver/mods:swag-cloudflare-real-ip";
      };
      environmentFiles = [
        config.sops.secrets.swag-env.path
      ];
      volumes = [
        "/containers/config/swag:/config:rw"
        # https://jellyfin.org/docs/general/networking/fail2ban/
        "/containers/config/jellyseerr/logs:/jellyseerr:ro"
        # https://docs.overseerr.dev/extending-overseerr/fail2ban
        # This blog provides a pre-made hybrid filter for fail2ban that works with both overseerr and jellyseerr
        # Pretty easy to arrive at it, but it's convenient
        # https://zzuo123.github.io/blog/securing-server/
        "/containers/config/jellyfin/log:/jellyfin:ro"
      ];
      ports = [
        "443:443/tcp"
        "80:80/tcp"
      ];
      log-driver = "journald";
      capabilities = {
        NET_ADMIN = true;
      };
      networks = [
        "exposed"
      ];
      tryRestart = false;
    };
  };
}
