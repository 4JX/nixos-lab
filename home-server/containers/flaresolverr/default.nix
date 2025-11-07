{ lib, config, ... }:

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
      image = "ghcr.io/flaresolverr/flaresolverr:latest";
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
      extraOptions = [
        "--network-alias=flaresolverr"
        "--network=arr"
      ];
    };
    systemd.services."docker-flaresolverr" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "no";
      };
      after = [
        "docker-network-arr.service"
      ];
      requires = [
        "docker-network-arr.service"
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
