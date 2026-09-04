{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.blocky;
  hsEnable = config.local.home-server.enable;
  hsCfg = config.local.home-server;
  swagInternalCfg = hsCfg.swag-internal;
  sopsFile = hsCfg.secretsFolder + "/home-server.yaml";

  generalUser = lib'.getUser "dockergeneral" "dockergeneral";
in
{
  options.local.home-server.blocky = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable Blocky.";
    };
    containerIp = lib.mkOption {
      type = lib.types.str;
      default = "172.31.254.53";
      description = "The fixed IP address for Blocky on the 0wireguard network.";
    };
  };

  config = lib.mkIf cfg.enable {
    assertions = [
      {
        assertion = swagInternalCfg.enable;
        message = "Blocky requires local.home-server.swag-internal.enable so the private wildcard can resolve to the internal ingress.";
      }
    ];

    sops.secrets = lib'.mkContainerSecret {
      containerName = "blocky";
      secretName = "blocky/internal-domain";
      inherit sopsFile;
    };

    sops.templates = lib'.mkContainerTemplate {
      containerName = "blocky";
      templateName = "blocky-mapping.yml";
      content = ''
        customDNS:
          customTTL: 1h
          filterUnmappedTypes: true
          mapping:
            ${config.sops.placeholder."blocky/internal-domain"}: ${swagInternalCfg.containerIp}
      '';
      inherit (generalUser) uid;
      inherit (generalUser) gid;
    };

    virtualisation.oci-containers.containers."blocky" = {
      image = "spx01/blocky:v0.34.0@sha256:595136fb127f4c952b621113e668c09acdcf15ac054d96ee6d4c51a76c35f5fd";
      volumes = [
        "${./blocky-base.yml}:/app/config.d/00-base.yml:ro"
        "${config.sops.templates."blocky-mapping.yml".path}:/app/config.d/10-mapping.yml:ro"
      ];
      cmd = [
        "--config"
        "/app/config.d"
      ];
      user = "${generalUser.uidStr}:${generalUser.gidStr}";
      log-driver = "journald";
      extraOptions = [
        "--ip=${cfg.containerIp}"
      ];
      networks = [
        "0wireguard"
      ];
      tryRestart = true;
    };
  };
}
