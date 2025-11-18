{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.beszel;
in
{
  imports = [
    ./beszel-agent.nix
    ./beszel.nix
    ./socket-proxy.nix
  ];

  config = lib.mkIf cfg.enable {
    # Configure networks
    virtualisation.oci-containers.networks = [
      { name = "beszel"; }
      {
        name = "socket-proxy-beszel";
        internal = true;
      }
    ];
  };
}
