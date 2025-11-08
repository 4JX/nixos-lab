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

  mediaUserString = builtins.toString config.users.users.dockermedia.uid;
  mediaGroupString = builtins.toString config.users.groups.dockermedia.gid;
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
      image = "gotson/komga:1.23.5@sha256:85f0be8920742341217f2b2bdafef64da1f6062ae472dcf74426a9fa549c8a05";
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
      user = "${mediaUserString}:${mediaGroupString}";
      log-driver = "journald";
      networks = [
        "arr"
        "exposed"
        "komga"
      ];
    };
    systemd.services = lib'.mkContainerSystemdService {
      containerName = "komga";
      tryRestart = false;
      networks = [
        "arr"
        "exposed"
        "komga"
      ];
    };
  };
}
