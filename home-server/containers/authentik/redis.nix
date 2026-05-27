{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.authentik.redis;
  hsEnable = config.local.home-server.enable;
  authentikEnable = config.local.home-server.authentik.enable;
in
{
  options = {
    local.home-server.authentik.redis.enable = lib.mkOption {
      type = lib.types.bool;
      default = authentikEnable && hsEnable;
      description = "Whether to enable the Authentik redis database.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."authentik-redis" = {
      image = "docker.io/library/redis:alpine@sha256:ad0a6eff0a40304ab1ab4f50f0dc192d82b071e1094eac961bcb6106092f8a4e";
      volumes = [
        "/containers/authentik/redis:/data:rw"
      ];
      cmd = [
        "--save"
        "60"
        "1"
        "--loglevel"
        "warning"
      ];
      log-driver = "journald";
      extraOptions = [
        "--health-cmd=redis-cli ping | grep PONG"
        "--health-interval=30s"
        "--health-retries=5"
        "--health-start-period=20s"
        "--health-timeout=3s"
      ];
      networks = [
        "authentik"
      ];
      tryRestart = true;
    };
  };
}
