# https://docs.goauthentik.io/docs/
{
  lib,
  config,
  ...
}:

let
  hsEnable = config.local.home-server.enable;
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
      default = hsEnable;
      description = "Whether to enable Authentik.";
    };
  };

  config = lib.mkIf cfg.enable {
    # Networks
    # Configure networks
    virtualisation.oci-containers.networks = [
      { name = "authentik"; }
      {
        # Used by authentik <> jellyfin
        name = "ldap";
        internal = true;
      }
    ];
  };
}
