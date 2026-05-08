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
      image = "docker.io/library/redis:alpine@sha256:b9646e7cdf8165d985b88bb3e61b3f2f7625db7f6c98af79def91997d04f26b9";
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
