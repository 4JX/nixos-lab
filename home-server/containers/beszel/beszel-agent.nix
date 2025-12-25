# https://github.com/wollomatic/socket-proxy
{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.beszel-agent;
  beszelEnable = config.local.home-server.beszel.enable;
  hsEnable = config.local.home-server.enable;

  generalUser = config.users.users.dockergeneral.uid;
  generalUserString = builtins.toString generalUser;
  generalGroup = config.users.groups.dockergeneral.gid;
  generalGroupString = builtins.toString generalGroup;
in
{
  options = {
    local.home-server.beszel-agent = {
      enable = lib.mkOption {
        type = lib.types.bool;
        default = hsEnable;
        description = "Whether to enable the Beszel agent.";
      };
      rootFs = lib.mkOption {
        type = lib.types.str;
        description = "Main filesystem used for monitoring disk stats.";
        default = "/";
      };
      monitoredFilesystems = lib.mkOption {
        type = lib.types.attrsOf lib.types.str;
        description = "Attrset of filesystems to be monitored, in format of <alias> = <mountpoint on given fs>";
        default = { };
        example = {
          root = "/";
          tank = "/tank";
        };
      };
      gpuMode = lib.mkOption {
        type = lib.types.enum [
          "none"
          "nvidia"
        ];
        description = "Support for given GPU in agent (at a cost of much larger container image).";
        default = "none";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    sops.secrets."beszel-agent/key" = {
      sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";
      uid = generalUser;
      gid = generalGroup;
    };
    sops.secrets."beszel-agent/token" = {
      sopsFile = config.local.home-server.secretsFolder + "/home-server.yaml";
      uid = generalUser;
      gid = generalGroup;
    };

    virtualisation.oci-containers.containers."beszel-agent" =
      (
        if (cfg.gpuMode == "nvidia") then
          {
            image = "ghcr.io/henrygd/beszel/beszel-agent-nvidia:0.16.1@sha256:7e0fed9d2f4162b162ce9378bfd8594753929be022392f4e9842db580b40e742";
          }
        else
          {
            image = "ghcr.io/henrygd/beszel/beszel-agent:0.16.1@sha256:fd6e2f8c86f9192b916d44640128ed36030cf2b9aee4ba750df660d929170ca8";
          }
      )
      // {
        environment = {
          # "LOG_LEVEL" = "debug";
          "DOCKER_HOST" = "tcp://dockerproxy-beszel:2375";
          "FILESYSTEM" = cfg.rootFs;
          "KEY_FILE" = "/secrets/key";
          "HUB_URL" = "http://beszel:8090";
          "TOKEN_FILE" = "/secrets/token";
          "LISTEN" = if (cfg.enable && beszelEnable) then "/beszel_socket/beszel.sock" else "45876";
        };
        volumes = [
          # https://www.beszel.dev/guide/environment-variables#data-dir
          # The agent relies on /proc/sys/kernel/random/boot_id since /etc/machine-id is empty within the container
          # https://github.com/shirou/gopsutil/blob/82391ff1253250c51db0fe42d400ae8975252ec7/host/host_linux.go#L33
          # https://github.com/henrygd/beszel/blob/26d367b188e8d73e0737dbd5a27d508207f63917/agent/agent.go#L213
          # https://github.com/henrygd/beszel/issues/1022
          "/containers/config/beszel-agent:/var/lib/beszel-agent:rw"
          "${config.sops.secrets."beszel-agent/key".path}:/secrets/key"
          "${config.sops.secrets."beszel-agent/token".path}:/secrets/token"
        ]
        ++ (builtins.map (
          name: "${builtins.getAttr name cfg.monitoredFilesystems}/.beszel:/extra-filesystems/${name}:ro"
        ) (builtins.attrNames cfg.monitoredFilesystems))
        ++ lib.optionals (cfg.enable && beszelEnable) [ "/containers/config/beszel/socket:/beszel_socket" ];
        dependsOn = [
          "dockerproxy-beszel"
        ];
        user = "${generalUserString}:${generalGroupString}";
        log-driver = "journald";
        # extraOptions = [
        #   "--network=host"
        # ];
        networks = [
          "beszel"
          "socket-proxy-beszel"
        ];
        devices = lib.optionals (cfg.gpuMode == "nvidia") [
          "nvidia.com/gpu=all"
        ];
        tryRestart = true;
      };
  };
}
