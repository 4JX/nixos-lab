{
  description = "Home server";

  outputs =
    inputs@{
      self,
      parts,
      treefmt-nix,
      ...
    }:
    parts.lib.mkFlake { inherit inputs; } {
      imports = [
        inputs.treefmt-nix.flakeModule
      ];

      systems = [ "x86_64-linux" ];

      perSystem =
        { pkgs, ... }:
        let
          treefmtEval = treefmt-nix.lib.evalModule pkgs ./fmt.nix;
        in
        {
          formatter = treefmtEval.config.build.wrapper;

          checks = {
            formatting = treefmtEval.config.build.check self;
          };
        };

      flake = {
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
    };

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";

    parts.url = "github:hercules-ci/flake-parts";

    # Project wide formatting
    treefmt-nix.url = "github:numtide/treefmt-nix";
  };
}
