{
  lib,
  config,
  pkgs,
  ...
}:

let
  hsEnable = config.ncfg.home-server.enable;
  cfg = config.ncfg.home-server.authentik;
in
{
  imports = [
    ./worker

    ./postgresql.nix
    ./redis.nix
    ./server.nix
  ];

  options = {
    ncfg.home-server.authentik.enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable Authentik.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Networks
    systemd.services."docker-network-authentik" = {
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "docker network rm -f authentik";
      };
      script = ''
        docker network inspect authentik || docker network create authentik
      '';
      partOf = [ "docker-compose-home-server-root.target" ];
      wantedBy = [ "docker-compose-home-server-root.target" ];
    };
    systemd.services."docker-network-ldap" = {
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "docker network rm -f ldap";
      };
      script = ''
        docker network inspect ldap || docker network create ldap
      '';
      partOf = [ "docker-compose-home-server-root.target" ];
      wantedBy = [ "docker-compose-home-server-root.target" ];
    };
  };
}
