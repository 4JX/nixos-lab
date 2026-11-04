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
      image = "gotson/komga:1.30.0@sha256:3ae42f88511211e0ec2637d88f3df1b709d07cfb093427e58444ae200a62608e";
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
