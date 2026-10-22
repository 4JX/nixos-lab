# https://github.com/wollomatic/socket-proxy
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.beszel;
  agentEnable = config.local.home-server.beszel-agent.enable;
  hsEnable = config.local.home-server.enable;

  generalUser = lib'.getUser "dockergeneral" "dockergeneral";
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
      image = "ghcr.io/henrygd/beszel/beszel:0.21.1@sha256:8514a69d9bbbcb74f371a3205561ee231fc0289739cea64e8131f341d695b770";
      volumes = [
        "/containers/config/beszel/data:/beszel_data"
      ]
      ++ lib.optionals (cfg.enable && agentEnable) [ "/containers/config/beszel/socket:/beszel_socket" ];
      ports = [
        "8100:8090/tcp"
      ];
      user = "${generalUser.uidStr}:${generalUser.gidStr}";
      log-driver = "journald";
      networks = [
        "beszel"
      ];
      tryRestart = true;
    };
  };
}
