{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.ncfg.home-server.dozzle;
  hsEnable = config.ncfg.home-server.enable;
in
{
  imports = [
    ./dozzle.nix
    ./socket-proxy.nix
  ];

  options = {
    ncfg.home-server.dozzle.enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable Dozzle.";
    };
  };

  config = lib.mkIf cfg.enable {
    systemd.services."docker-network-dozzle" = {
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "docker network rm -f dozzle";
      };
      script = ''
        docker network inspect dozzle || docker network create dozzle
      '';
      partOf = [ "docker-compose-home-server-root.target" ];
      wantedBy = [ "docker-compose-home-server-root.target" ];
    };

    systemd.services."docker-network-socket-proxy-dozzle" = {
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "docker network rm -f socket-proxy-dozzle";
      };
      script = ''
        docker network inspect socket-proxy-dozzle || docker network create socket-proxy-dozzle
      '';
      partOf = [ "docker-compose-home-server-root.target" ];
      wantedBy = [ "docker-compose-home-server-root.target" ];
    };
  };
}
