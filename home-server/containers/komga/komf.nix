{ lib, config, ... }:

let
  cfg = config.local.home-server.komf;
  hsEnable = config.local.home-server.enable;

  mediaUser = config.users.users.dockermedia.uid;
  mediaGroup = config.users.groups.dockermedia.gid;
  mediaUserString = builtins.toString mediaUser;
  mediaGroupString = builtins.toString mediaGroup;
in
{
  options = {
    local.home-server.komf = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = hsEnable;
        description = "Whether to enable Komf.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets.komf = {
      sopsFile = config.local.home-server.secretsFolder + "/komf-application.yml";
      # Serve the whole YAML file
      key = "";
      uid = mediaUser;
      gid = mediaGroup;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."komf" = {
      image = "sndxr/komf:latest";
      environment = {
        "KOMF_LOG_LEVEL" = "INFO";
      };
      volumes = [
        # https://github.com/Snd-R/komf?tab=readme-ov-file#example-applicationyml-config
        "${config.sops.secrets.komf.path}:/config/application.yml:ro"
        "/containers/config/komf:/config:rw"
      ];
      ports = [
        "8085:8085/tcp"
      ];
      user = "${mediaUserString}:${mediaGroupString}";
      log-driver = "journald";
      extraOptions = [
        "--network-alias=komf"
        "--network=komga"
      ];
    };
    systemd.services."docker-komf" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "always";
        RestartMaxDelaySec = lib.mkOverride 90 "1m";
        RestartSec = lib.mkOverride 90 "100ms";
        RestartSteps = lib.mkOverride 90 9;
      };
      after = [
        "docker-network-komga.service"
      ];
      requires = [
        "docker-network-komga.service"
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
