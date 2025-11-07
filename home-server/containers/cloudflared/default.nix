{ lib, config, ... }:

let
  cfg = config.local.home-server.cloudflared;
  hsEnable = config.local.home-server.enable;

  proxyUser = config.users.users.dockerproxy.uid;
  proxyGroup = config.users.groups.dockerproxy.gid;
  proxyUserString = builtins.toString proxyUser;
  proxyGroupString = builtins.toString proxyGroup;
in
{
  options = {
    local.home-server.cloudflared.enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable CloudFlared.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.cloudflared-env = {
      sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";
      uid = proxyUser;
      gid = proxyGroup;
    };

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
      user = "${proxyUserString}:${proxyGroupString}";
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
