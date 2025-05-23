{
  lib,
  config,
  pkgs,
  ...
}:

let
  cfg = config.local.home-server.homarr;
  hsCfg = config.local.home-server;
  hsEnable = hsCfg.enable;
in
{
  imports = [
    ./homarr.nix
    ./socket-proxy.nix
  ];

  options = {
    local.home-server.homarr.enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable Homarr.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Extracted from docker-compose.nix
    systemd.services."docker-network-homarr" = {
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "docker network rm -f homarr";
      };
      script = ''
        docker network inspect homarr || docker network create homarr
      '';
      partOf = [ "docker-compose-home-server-root.target" ];
      wantedBy = [ "docker-compose-home-server-root.target" ];
    };

    systemd.services."docker-network-socket-proxy-homarr" = {
      path = [ pkgs.docker ];
      serviceConfig = {
        Type = "oneshot";
        RemainAfterExit = true;
        ExecStop = "docker network rm -f socket-proxy-homarr";
      };
      script = ''
        docker network inspect socket-proxy-homarr || docker network create socket-proxy-homarr
      '';
      partOf = [ "docker-compose-home-server-root.target" ];
      wantedBy = [ "docker-compose-home-server-root.target" ];
    };
  };
}
