{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.flaresolverr;
  hsEnable = config.local.home-server.enable;
in
{
  options.local.home-server.flaresolverr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable FlareSolverr.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."flaresolverr" = {
      image = "ghcr.io/flaresolverr/flaresolverr:v3.4.6@sha256:7962759d99d7e125e108e0f5e7f3cdbcd36161776d058d1d9b7153b92ef1af9e";
      environment = {
        "LOG_LEVEL" = "info";
        "LOG_HTML" = "false";
        "CAPTCHA_SOLVER" = "none";
        "TZ" = config.time.timeZone;
      };
      ports = [
        "8191:8191/tcp"
      ];
      log-driver = "journald";
      networks = [
        "arr"
      ];
      tryRestart = false;
    };
  };
}
