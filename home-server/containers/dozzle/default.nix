{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.dozzle;
  hsEnable = config.local.home-server.enable;
in
{
  imports = [
    ./dozzle.nix
    ./socket-proxy.nix
  ];

  options = {
    local.home-server.dozzle.enable = lib.mkOption {
      type = lib.types.bool;
      default = hsEnable;
      description = "Whether to enable Dozzle.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure networks
    virtualisation.oci-containers.networks = [
      { name = "dozzle"; }
      {
        name = "socket-proxy-dozzle";
        internal = true;
      }
    ];
  };
}
