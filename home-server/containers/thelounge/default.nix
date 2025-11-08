# https://thelounge.chat/docs
{ lib, config, ... }:

let
  cfg = config.local.home-server.thelounge;
  hsEnable = config.local.home-server.enable;

  generalUserString = builtins.toString config.users.users.dockergeneral.uid;
  generalGroupString = builtins.toString config.users.groups.dockergeneral.gid;
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
    # Extracted from docker-compose.nix
    virtualisation.oci-containers.containers."thelounge" = {
      image = "ghcr.io/thelounge/thelounge:4.4.3@sha256:c2aa0916203b298ffaf3a36c4eb60ef73c1006448d430e218d37840472e84e50";
      volumes = [
        "/containers/config/thelounge:/var/opt/thelounge:rw"
      ];
      ports = [
        "9010:9000/tcp"
      ];
      user = "${generalUserString}:${generalGroupString}";
      log-driver = "journald";
      networks = [
        "thelounge"
      ];
    };
    systemd.services."docker-thelounge" = {
      serviceConfig = {
        Restart = lib.mkOverride 90 "no";
      };
      after = [
        "docker-network-thelounge.service"
      ];
      requires = [
        "docker-network-thelounge.service"
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
