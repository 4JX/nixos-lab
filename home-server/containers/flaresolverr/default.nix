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
      image = "ghcr.io/flaresolverr/flaresolverr:v3.5.2@sha256:c80ae007ce2ccdcd217a12426e4f039ef763ff90738c808d38810c3e59323767";
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
