{ lib, config, ... }:

let
  cfg = config.ncfg.home-server.cloudflared;
  hsEnable = config.ncfg.home-server.enable;

  secretsFile.sopsFile = config.ncfg.home-server.secretsFolder + "/home-server.yaml";
in
{
  options = {
    ncfg.home-server.cloudflared.enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable CloudFlared.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.cloudflared-env = secretsFile;

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."cloudflared" = {
      image = "cloudflare/cloudflared";
      environmentFiles = [
        config.sops.secrets.cloudflared-env.path
      ];
      cmd = [
        "tunnel"
        "run"
      ];
      log-driver = "journald";
      extraOptions = [
        "--network-alias=cloudflared-tunnel"
        "--network=exposed"
      ];
    };
    systemd.services."docker-cloudflared" = {
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
