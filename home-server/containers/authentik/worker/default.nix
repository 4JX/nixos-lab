{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.authentik.worker;
  hsEnable = config.local.home-server.enable;
  authentikEnable = config.local.home-server.authentik.enable;
in
{
  imports = [
    ./socket-proxy.nix
    ./worker.nix
  ];

  options = {
    local.home-server.authentik.worker.enable = lib.mkOption {
      type = lib.types.bool;
      default = authentikEnable && hsEnable;
      description = "Whether to enable the Authentik worker.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure networks
    local.home-server.containers.networks = [
      {
        name = "socket-proxy-authentik-worker";
        internal = true;
      }
    ];
  };
}
