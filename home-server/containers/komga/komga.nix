# https://github.com/gotson/komga
# https://komga.org/docs/category/installation
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.komga;
  hsEnable = config.local.home-server.enable;

  mediaUser = lib'.getUser "dockermedia" "dockermedia";
in
{
  options = {
    local.home-server.komga = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = hsEnable;
        description = "Whether to enable Komga.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."komga" = {
      # https://komga.org/docs/installation/docker#version-tags
      image = "gotson/komga:1.24.4@sha256:dae630271561b642d47c9723803ec77900d1f0a803fbe6a42da69db5b21ebaeb";
      environment = {
        "TZ" = config.time.timeZone;
        # https://komga.org/docs/installation/docker#increase-memory-limit
        # - JAVA_TOOL_OPTIONS=-Xmx4g
      };
      volumes = [
        "/containers/config/komga:/config:rw"
        "/containers/mediaserver/media:/data:rw"
      ];
      ports = [
        "25600:25600/tcp"
      ];
      user = "${mediaUser.uidStr}:${mediaUser.gidStr}";
      log-driver = "journald";
      networks = [
        "arr"
        "exposed"
        "komga"
      ];
      tryRestart = false;
    };
  };
}
