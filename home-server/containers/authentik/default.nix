# https://docs.goauthentik.io/docs/
{
  lib,
  config,
  ...
}:

let
  cfg = config.local.home-server.authentik;
in
{
  imports = [
    ./worker

    ./postgresql.nix
    ./redis.nix
    ./server.nix
  ];

  options = {
    local.home-server.authentik.enable = lib.mkOption {
      type = lib.types.bool;
      default = false;
      description = "Whether to enable Authentik.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Configure networks
    virtualisation.oci-containers.networks = [
      { name = "authentik"; }
    ];
  };
}
