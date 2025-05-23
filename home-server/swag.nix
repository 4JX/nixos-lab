{ lib, config, ... }:

let
  cfg = config.local.home-server.swag;
  hsEnable = config.local.home-server.enable;

  secretsFile.sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";
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
    sops.secrets.swag-env = secretsFile;

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."swag" = {
      image = "lscr.io/linuxserver/swag";
      environment = {
        "CERTPROVIDER" = "";
        "DNSPLUGIN" = "cloudflare";
        "DOCKER_MODS" = "linuxserver/mods:swag-cloudflare-real-ip";
        "EXTRA_DOMAINS" = "";
        "ONLY_SUBDOMAINS" = "false";
        "PGID" = "1000";
        "PUID" = "1000";
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
