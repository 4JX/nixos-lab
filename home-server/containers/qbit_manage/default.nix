# https://github.com/StuffAnThings/qbit_manage/wiki
{ lib, config, ... }:

let
  cfg = config.local.home-server.qbit_manage;
  hsCfg = config.local.home-server;
  hsEnable = hsCfg.enable;

  mediaUser = config.users.users.dockermedia.uid;
  mediaGroup = config.users.groups.dockermedia.gid;
  mediaUserString = builtins.toString mediaUser;
  mediaGroupString = builtins.toString mediaGroup;
in
{
  options = {
    local.home-server.qbit_manage.enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable qbit_manage.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.qbit_manage = {
      sopsFile = hsCfg.secretsFolder + "/qbit_manage.yml";
      # Serve the whole YAML file
      key = "";

      uid = mediaUser;
      gid = mediaGroup;
      # Read+Write needed by qbit_manage
      mode = "0600";
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."qbit_manage" = {
      image = "ghcr.io/stuffanthings/qbit_manage:latest";
      environment = {
        "QBT_RUN" = "false";
        "QBT_SCHEDULE" = "1440";
        "QBT_CONFIG" = "config.yml";
        "QBT_LOGFILE" = "activity.log";
        "QBT_CROSS_SEED" = "false";
        "QBT_RECHECK" = "false";
        "QBT_CAT_UPDATE" = "false";
        "QBT_TAG_UPDATE" = "false";
        "QBT_REM_UNREGISTERED" = "false";
        "QBT_REM_ORPHANED" = "false";
        "QBT_TAG_TRACKER_ERROR" = "false";
        "QBT_TAG_NOHARDLINKS" = "false";
        "QBT_SHARE_LIMITS" = "false";
        "QBT_SKIP_CLEANUP" = "false";
        "QBT_DRY_RUN" = "false";
        "QBT_LOG_LEVEL" = "INFO";
        "QBT_DIVIDER" = "=";
        "QBT_WIDTH" = "100";
      };
      volumes = [
        "/containers/config/qbit_manage/:/config:rw"
        "${config.sops.secrets.qbit_manage.path}:/config/config.yml:rw"
        "/containers/mediaserver/torrents/:/data/torrents:rw"
        "/containers/config/qbittorrent:/qbittorrent:ro"
      ];
      dependsOn = [
        "qbittorrent"
      ];
      user = "${mediaUserString}:${mediaGroupString}";
      log-driver = "journald";
      extraOptions = [
        "--network-alias=qbit_manage"
        "--network=arr"
      ];
    };
    systemd.services."docker-qbit_manage" = {
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
