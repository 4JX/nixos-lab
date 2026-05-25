{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.cloudflared;
  hsEnable = config.local.home-server.enable;

  proxyUser = lib'.getUser "dockerproxy" "dockerproxy";
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
    sops.secrets = lib'.mkContainerSecret {
      containerName = "cloudflared";
      secretName = "cloudflared-env";
      sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";
      inherit (proxyUser) uid;
      inherit (proxyUser) gid;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."cloudflared" = {
      image = "cloudflare/cloudflared:2026.5.1@sha256:a5b5e6fd9a372f054b9a843c219bfbcdceb54691605312a8b1ee72978bdf1aa1";
      environmentFiles = [
        config.sops.secrets.cloudflared-env.path
      ];
      cmd = [
        "tunnel"
        "run"
      ];
      user = "${proxyUser.uidStr}:${proxyUser.gidStr}";
      log-driver = "journald";
      networks = [
        "exposed"
      ];
      tryRestart = false;
    };
  };
}
