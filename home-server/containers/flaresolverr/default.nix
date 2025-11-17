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
      image = "ghcr.io/flaresolverr/flaresolverr:v3.4.5@sha256:4f4e5f759aa3a9a64305e99188ea1db1ec2944a5e7d290d2b089af5f2f6f48e4";
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
