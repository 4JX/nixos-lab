{
  lib,
  lib',
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
      image = "ghcr.io/flaresolverr/flaresolverr:v3.4.4@sha256:06c76759d062c185d8ac0b48f302258645b8d99db86109a3d6dce3209d93de51";
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
    };
    systemd.services = lib'.mkContainerSystemdService {
      containerName = "flaresolverr";
      tryRestart = false;
      networks = [
        "arr"
      ];
    };
  };
}
