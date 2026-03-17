# https://github.com/Snd-R/komf
# https://github.com/Snd-R/komf-userscript
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.komf;
  hsEnable = config.local.home-server.enable;

  mediaUser = lib'.getUser "dockermedia" "dockermedia";
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
    sops.secrets = lib'.mkContainerSecret {
      containerName = "komf";
      secretName = "komf";
      sopsFile = config.local.home-server.secretsFolder + "/komf-application.yml";
      # Serve the whole YAML file
      key = "";
      inherit (mediaUser) uid;
      inherit (mediaUser) gid;
    };

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."komf" = {
      image = "sndxr/komf:1.7.1@sha256:4a6971a76abc30869f6d0555a7328ff8cd879f3016a7378395df331c1245cbb2";
      environment = {
        "KOMF_LOG_LEVEL" = "INFO";
        # optional jvm options. Example config for low memory usage. Runs guaranteed cleanup up every 3600000ms(1hour)
        # - JAVA_TOOL_OPTIONS=-XX:+UnlockExperimentalVMOptions -XX:+UseShenandoahGC -XX:ShenandoahGCHeuristics=compact -XX:ShenandoahGuaranteedGCInterval=3600000 -XX:TrimNativeHeapInterval=3600000
      };
      volumes = [
        # https://github.com/Snd-R/komf?tab=readme-ov-file#example-applicationyml-config
        "${config.sops.secrets.komf.path}:/config/application.yml:ro"
        "/containers/config/komf:/config:rw"
      ];
      ports = [
        "8085:8085/tcp"
      ];
      user = "${mediaUser.uidStr}:${mediaUser.gidStr}";
      log-driver = "journald";
      networks = [
        "komga"
      ];
      tryRestart = true;
    };
  };
}
