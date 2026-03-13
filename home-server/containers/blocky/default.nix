{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.blocky;
  hsEnable = config.local.home-server.enable;
  hsCfg = config.local.home-server;
  swagInternalCfg = hsCfg.swag-internal;
  sopsFile = hsCfg.secretsFolder + "/home-server.yaml";

  generalUser = config.users.users.dockergeneral.uid;
  generalUserString = builtins.toString generalUser;
  generalGroup = config.users.groups.dockergeneral.gid;
  generalGroupString = builtins.toString generalGroup;
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

    sops.secrets."blocky/internal-domain" = {
      inherit sopsFile;
    };

    sops.templates."blocky-mapping.yml" = {
      content = ''
        customDNS:
          customTTL: 1h
          filterUnmappedTypes: true
          mapping:
            ${config.sops.placeholder."blocky/internal-domain"}: ${swagInternalCfg.containerIp}
      '';
      uid = generalUser;
      gid = generalGroup;
    };

    virtualisation.oci-containers.containers."blocky" = {
      image = "spx01/blocky:v0.29.0@sha256:a6d99f323d3036a99a3767a52ad612f4d8f3f31167492bfc14d4ea57b24cdfd0";
      volumes = [
        "${./blocky-base.yml}:/app/config.d/00-base.yml:ro"
        "${config.sops.templates."blocky-mapping.yml".path}:/app/config.d/10-mapping.yml:ro"
      ];
      cmd = [
        "--config"
        "/app/config.d"
      ];
      user = "${generalUserString}:${generalGroupString}";
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
