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
            prowlarr.autoStart = true;
            qbittorrent.autoStart = true;
            thelounge.autoStart = true;
          };
        };
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    compose2nix = {
      url = "github:aksiksi/compose2nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };
}
