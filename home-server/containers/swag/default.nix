{ lib, config, ... }:

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
      image = "lscr.io/linuxserver/swag";
      environment = {
        "CERTPROVIDER" = "";
        "DNSPLUGIN" = "cloudflare";
        "DOCKER_MODS" = "linuxserver/mods:swag-cloudflare-real-ip";
        "EXTRA_DOMAINS" = "";
        "ONLY_SUBDOMAINS" = "false";
        "PGID" = proxyGroupString;
        "PUID" = proxyUserString;
        "STAGING" = "false";
        "SUBDOMAINS" = "wildcard";
        "SWAG_AUTORELOAD" = "true";
        "TZ" = config.time.timeZone;
        "VALIDATION" = "dns";
      };
      environmentFiles = [
        config.sops.secrets.swag-env.path
      ];
      volumes = [
        "/containers/config/jellyfin/log:/jellyfin:ro"
        "/containers/config/jellyseerr/logs:/jellyseerr:ro"
        "/containers/config/swag:/config:rw"
      ];
      ports = [
        "443:443/tcp"
        "80:80/tcp"
      ];
      log-driver = "journald";
      extraOptions = [
        "--cap-add=NET_ADMIN"
        "--network-alias=swag"
        "--network=exposed"
      ];
    };
    systemd.services."docker-swag" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "no";
      };
      after = [
        "docker-network-exposed.service"
      ];
      requires = [
        "docker-network-exposed.service"
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
