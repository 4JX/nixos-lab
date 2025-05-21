{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.ncfg.home-server.ddns;
  hsEnable = config.ncfg.home-server.enable;

  sopsFile = config.ncfg.home-server.secretsFolder + "/home-server.yaml";
in
{
  options.ncfg.home-server.ddns = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable DDNS";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.cloudflare-ddns-env = {
      inherit sopsFile;
    };

    systemd.services.cloudflare-ddns = {
      reloadIfChanged = false;
      restartIfChanged = false;
      stopIfChanged = false;

      wantedBy = [ "multi-user.target" ];
      wants = [ "network-online.target" ];
      after = [ "network-online.target" ];

      startAt = "hourly";

      serviceConfig = {
        EnvironmentFile = config.sops.secrets.cloudflare-ddns-env.path;
        DynamicUser = true;
      };

      path = [
        pkgs.unixtools.ping
        pkgs.netcat
        pkgs.jq
        pkgs.curl
      ];

      script = builtins.readFile ./cloudflare_ddns.sh;
    };
  };
}
