{
  description = "Home server";

  outputs =
    { ... }:
    {
      nixosModules.default = ./home-server;
      nixosModules.default-enabled =
        { ... }:
        {
          imports = [ ./home-server ];

          local.home-server = {
            enable = true;
            jellyfin.firewall.open = false;
            jellyseerr.firewall.open = false;
          };
        };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };
}
