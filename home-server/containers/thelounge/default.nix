# https://thelounge.chat/docs
{
  lib,
  lib',
  config,
  ...
}:

let
  cfg = config.local.home-server.thelounge;
  hsEnable = config.local.home-server.enable;

  generalUser = lib'.getUser "dockergeneral" "dockergeneral";
in
{
  options.local.home-server.thelounge = {
    enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable thelounge.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure networks
    virtualisation.oci-containers.networks = [
      { name = "thelounge"; }
    ];

    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."thelounge" = {
      image = "ghcr.io/thelounge/thelounge:4.4.3@sha256:9a7ca90fb5e2c9d86910497f3fa40d4fff3372a63b5e2b4eca1674a1f9a7e958";
      volumes = [
        "/containers/config/thelounge:/var/opt/thelounge:rw"
      ];
      ports = [
        "9010:9000/tcp"
      ];
      user = "${generalUser.uidStr}:${generalUser.gidStr}";
      log-driver = "journald";
      networks = [
        "thelounge"
      ];
      tryRestart = false;
    };
  };
}
