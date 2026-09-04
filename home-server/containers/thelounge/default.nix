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
      image = "ghcr.io/thelounge/thelounge:4.5.2@sha256:3cc53915661c923e89769f61185db89ad7a2ab682d1fe20b48e8ab287fd753d3";
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
