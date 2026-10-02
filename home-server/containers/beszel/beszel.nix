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
      image = "ghcr.io/henrygd/beszel/beszel:0.21.0@sha256:020d80f5974e66356e6d6440736952edc9b9ea59978ac9f98418b5fb643dc0e2";
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
