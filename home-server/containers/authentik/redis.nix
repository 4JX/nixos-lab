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
      image = "docker.io/library/redis:alpine@sha256:81b6f81d6a6c5b9019231a2e8eb10085e3a139a34f833dcc965a8a959b040b72";
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
