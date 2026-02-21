# https://github.com/wollomatic/socket-proxy
{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.beszel;
  agentEnable = config.local.home-server.beszel-agent.enable;
  hsEnable = config.local.home-server.enable;

  generalUserString = builtins.toString config.users.users.dockergeneral.uid;
  generalGroupString = builtins.toString config.users.groups.dockergeneral.gid;
in
{
  options = {
    local.home-server.beszel.enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable Beszel.";
    };
  };

  config = lib.mkIf cfg.enable {
    virtualisation.oci-containers.containers."beszel" = {
      image = "ghcr.io/henrygd/beszel/beszel:0.18.4@sha256:04049e827455f4de51e3fd213bd2cd076138f7ddedf8e57ae94d55ab5c4893d1";
      volumes = [
        "/containers/config/beszel/data:/beszel_data"
      ]
      ++ lib.optionals (cfg.enable && agentEnable) [ "/containers/config/beszel/socket:/beszel_socket" ];
      ports = [
        "8100:8090/tcp"
      ];
      user = "${generalUserString}:${generalGroupString}";
      log-driver = "journald";
      networks = [
        "beszel"
      ];
      tryRestart = true;
    };
  };
}
