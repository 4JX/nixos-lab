# https://github.com/Suwayomi/Suwayomi-Server
# https://github.com/suwayomi/Suwayomi-Server-docker
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.suwayomi;
  hsEnable = config.local.home-server.enable;

  mediaUser = lib'.getUser "dockermedia" "dockermedia";
in

{
  options = {
    local.home-server.suwayomi.enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable Suwayomi.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib'.mkContainerSecret {
      containerName = "suwayomi";
      secretName = "suwayomi-env";
      sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";
      inherit (mediaUser) uid;
      inherit (mediaUser) gid;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."suwayomi" = {
      image = "ghcr.io/suwayomi/suwayomi-server:v2.1.2092@sha256:ba7e3dcd597704f5fbe4f2fa81561b3f8161eba81fcd546464894a1c616db870";
      environment = {
        "DEBUG" = "false";
        "TZ" = config.time.timeZone;
      };
      environmentFiles = [
        config.sops.secrets.suwayomi-env.path
      ];
      volumes = [
        # The save path is hardcoded
        # https://github.com/Suwayomi/Suwayomi-Server-docker?tab=readme-ov-file#downloads-folder
        "/containers/config/suwayomi:/home/suwayomi/.local/share/Tachidesk:rw"
        "/containers/mediaserver/media/comics/suwayomi/downloads:/home/suwayomi/.local/share/Tachidesk/downloads:rw"
      ];
      ports = [
        "4567:4567/tcp"
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
