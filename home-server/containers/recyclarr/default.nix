{ config, lib, ... }:

# TODO: More granular profile management with https://recyclarr.dev/wiki/yaml/config-reference/ and https://github.com/MasterMidi/nixos-config/blob/d26bd35bfb328bab2c5dc2733bc1c7de5e2c4faa/hosts/servers/david/recyclarr/
# Written via pkgs.writers.writeYAML "recyclarr.yaml" { settings = "foo"; } since it gives more flexibility
# Or at least with includes https://recyclarr.dev/wiki/yaml/config-reference/include/
let
  # https://recyclarr.dev/wiki/guide-configs/
  recyclarrYaml = ./recyclarr.yml;

  hsCfg = config.local.home-server;
  cfg = hsCfg.recyclarr;

  sonarrEnabled = hsCfg.sonarr.tv-hd.enable || hsCfg.sonarr.anime.enable;
  radarrEnabled = hsCfg.radarr.movies-hd.enable || hsCfg.radarr.movies-uhd.enable;

  mediaUser = config.users.users.dockermedia.uid;
  mediaGroup = config.users.groups.dockermedia.gid;
  mediaUserString = builtins.toString mediaUser;
  mediaGroupString = builtins.toString mediaGroup;
in
{
  options.local.home-server.recyclarr = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = sonarrEnabled || radarrEnabled;
      description = "Whether to enable the Recyclarr service.";
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.recyclarr = {
      sopsFile = hsCfg.secretsFolder + "/recyclarr.yaml";
      # Serve the whole YAML file
      key = "";
      # The container will also run as the same user/group
      uid = mediaUser;
      gid = mediaGroup;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."recyclarr" = {
      image = "ghcr.io/recyclarr/recyclarr";
      environment = {
        "TZ" = config.time.timeZone;
      };
      volumes = [
        "${recyclarrYaml}:/config/recyclarr.yml:rw"
        "${config.sops.secrets.recyclarr.path}:/config/secrets.yml:rw"
        "/containers/config/recyclarr:/config:rw"
      ];
      dependsOn = [
        "radarr-movies-hd"
        "sonarr-tv-hd"
        "sonarr-anime"
      ];
      user = "${mediaUserString}:${mediaGroupString}";
      log-driver = "journald";
      extraOptions = [
        "--network-alias=recyclarr"
        "--network=arr"
      ];
    };
    systemd.services."docker-recyclarr" = {
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
