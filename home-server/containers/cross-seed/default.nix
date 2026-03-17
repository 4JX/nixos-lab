# https://www.cross-seed.org/docs
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.cross-seed;
  hsEnable = config.local.home-server.enable;

  mediaUser = lib'.getUser "dockermedia" "dockermedia";
in
{
  options.local.home-server.cross-seed = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable cross-seed.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets = lib'.mkContainerSecret {
      containerName = "cross-seed";
      secretName = "cross-seed-config";
      sopsFile = config.local.home-server.secretsFolder + "/cross-seed-config.js";
      format = "binary";
      inherit (mediaUser) uid;
      inherit (mediaUser) gid;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."cross-seed" = {
      image = "ghcr.io/cross-seed/cross-seed:6.13.6@sha256:e2bf5b593e4e7d699e6242423ad7966190cd52ba8eefafdfdbb0cb5b0b609b96";
      volumes = [
        "/containers/config/cross-seed:/config:rw"
        "${config.sops.secrets.cross-seed-config.path}:/config/config.js:ro"
        "/containers/config/qbittorrent/data/BT_backup:/torrents:ro"
        "/containers/mediaserver/torrents:/data/torrents:rw"
      ];
      ports = [
        "2468:2468/tcp"
      ];
      cmd = [ "daemon" ];
      user = "${mediaUser.uidStr}:${mediaUser.gidStr}";
      log-driver = "journald";
      networks = [
        "arr"
      ];
      tryRestart = false;
    };
  };
}
