{
  lib,
  config,
  ...
}:

let
  komgaCfg = config.local.home-server.komga;
  komfCfg = config.local.home-server.komf;
in
{
  imports = [
    ./komga.nix
    ./komf.nix
  ];

  config = lib.mkIf (komgaCfg.enable || komfCfg.enable) {
    # Configure networks
    virtualisation.oci-containers.networks = [
      {
        name = "komga";
        internal = true;
      }
    ];
  };
}
