# https://github.com/Suwayomi/Suwayomi-Server
# https://github.com/suwayomi/Suwayomi-Server-docker
{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.suwayomi;
  hsEnable = config.local.home-server.enable;

  mediaUser = config.users.users.dockermedia.uid;
  mediaGroup = config.users.groups.dockermedia.gid;
  mediaUserString = builtins.toString mediaUser;
  mediaGroupString = builtins.toString mediaGroup;
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
    sops.secrets.suwayomi-env = {
      sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";
      uid = mediaUser;
      gid = mediaGroup;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."suwayomi" = {
      image = "ghcr.io/suwayomi/suwayomi-server:v2.1.2071@sha256:f9e2f9fd4ed43181f6e9ed890ec8c5e79048e388ddee00e924dc7e86b79170ca";
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
      user = "${mediaUserString}:${mediaGroupString}";
      log-driver = "journald";
      networks = [
        "arr"
      ];
      tryRestart = false;
    };
  };
}
