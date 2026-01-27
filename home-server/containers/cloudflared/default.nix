{
  lib,
  config,
  ...
}:

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
      image = "cloudflare/cloudflared:2026.1.2@sha256:e9bcb2ef08d25632ff74344e73a025f4f4bf12718335b196fa0e670cacace8c5";
      environmentFiles = [
        config.sops.secrets.cloudflared-env.path
      ];
      cmd = [
        "tunnel"
        "run"
      ];
      user = "${proxyUserString}:${proxyGroupString}";
      log-driver = "journald";
      networks = [
        "exposed"
      ];
      tryRestart = false;
    };
  };
}
