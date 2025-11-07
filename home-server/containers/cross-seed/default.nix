# https://www.cross-seed.org/docs
{ lib, config, ... }:

let
  cfg = config.local.home-server.cross-seed;
  hsEnable = config.local.home-server.enable;

  mediaUser = config.users.users.dockermedia.uid;
  mediaGroup = config.users.groups.dockermedia.gid;
  mediaUserString = builtins.toString mediaUser;
  mediaGroupString = builtins.toString mediaGroup;
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
    sops.secrets.cross-seed-config = {
      sopsFile = config.local.home-server.secretsFolder + "/cross-seed-config.js";
      format = "binary";
      uid = mediaUser;
      gid = mediaGroup;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."cross-seed" = {
      image = "ghcr.io/cross-seed/cross-seed:6";
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
      user = "${mediaUserString}:${mediaGroupString}";
      log-driver = "journald";
      extraOptions = [
        "--network-alias=cross-seed"
        "--network=arr"
      ];
    };
    systemd.services."docker-cross-seed" = {
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
      # Do not start cross-seed if qbittorrent is not set to  as well
      # This avoids qbittorrent being started by proxy due to cross-seed's wantedBy+dependsOn
      wantedBy = [
        "docker-compose-home-server-root.target"
      ];
    };
  };
}
