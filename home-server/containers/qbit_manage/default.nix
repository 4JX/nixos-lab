# https://github.com/StuffAnThings/qbit_manage/wiki
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.qbit_manage;
  hsCfg = config.local.home-server;
  hsEnable = hsCfg.enable;

  mediaUser = lib'.getUser "dockermedia" "dockermedia";
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
    sops.secrets = lib'.mkContainerSecret {
      containerName = "qbit_manage";
      secretName = "qbit_manage";
      sopsFile = hsCfg.secretsFolder + "/qbit_manage.yml";
      # Serve the whole YAML file
      key = "";

      inherit (mediaUser) uid;
      inherit (mediaUser) gid;
      # Read+Write needed by qbit_manage
      mode = "0600";
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."qbit_manage" = {
      image = "ghcr.io/stuffanthings/qbit_manage:v4.7.0@sha256:8786f2efc6fb8e26281f09bf6c5d0004e2d2420fd4781af0aed123ae01558e21";
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
      user = "${mediaUser.uidStr}:${mediaUser.gidStr}";
      log-driver = "journald";
      networks = [
        "arr"
      ];
      tryRestart = false;
    };
  };
}
