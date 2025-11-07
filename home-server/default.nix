# Do I need this? https://github.com/rasmus-kirk/nixarr?tab=readme-ov-file
# Nice inspiration: https://github.com/painerp/nixos/blob/339554807b155d54b1e9a996d9693fec77d86f39/containers/gluetun.nix

# Alternatively for containers:
# https://github.com/hercules-ci/arion
# https://nixos.wiki/wiki/NixOS_Containers

{
  lib,
  lib',
  config,
  pkgs,
  ...
}:

let
  cfg = config.local.home-server;
  # systemUsers = lib.attrNames config.users.users;
in
{
  imports = [
    ./lib
    ./nets.nix

    ./containers

    ./ddns

    ./nvidia-ctk.nix
    ./permissions.nix
    ./tor.nix
  ];

  options.local.home-server = {
    enable = lib.mkEnableOption "the home-server module" // {
      enable = true;
    };
    secretsFolder = lib.mkOption {
      type = lib.types.path;
      default = ../secrets/hs;
      description = "The path to the home-server secrets folder.";
    };
    rootTargetName = lib.mkOption {
      type = lib.types.str;
      default = "home-server";
      description = "The name of the root target.";
    };
    backend = lib.mkOption {
      type = lib.types.enum [
        "podman"
        "docker"
      ];
      default = "docker";
      description = "The underlying Docker implementation to use.";
    };
    containers = {
      networks = lib.mkOption {
        type = lib.types.listOf (
          lib.types.submodule {
            options = {
              name = lib.mkOption {
                type = lib.types.str;
                description = "Name of the network used by containers.";
                example = "mynetwork";
              };
              subnet = lib.mkOption {
                type = lib.types.str;
                description = "Subnet of the network user by containers.";
                example = "172.30.0.0/16";
              };
              internal = lib.mkOption {
                type = lib.types.bool;
                default = false;
                description = "Whether the network is internal.";
              };
            };
          }
        );
        default = [ ];
        example = [
          {
            name = "mynetwork";
            subnet = "172.30.0.0/16";
            hostIP = "172.30.0.1";
          }
        ];
        description = "List of extra networks created for docker.";
      };
    };
  };

  config = lib.mkIf cfg.enable {
    environment.systemPackages = [
      pkgs.docker-compose
    ];

    virtualisation.oci-containers.backend = cfg.backend;

    # Runtime
    # TODO: Select backend
    virtualisation.docker = {
      enable = true;
      autoPrune.enable = true;
    };

    system.services = lib.pipe [
      (builtins.map (network: lib'.mkNetworkService network))
      lib.mergeAttrsList
    ] cfg.networks;

    # Root service
    # When started, this will automatically create all resources and start
    # the containers. When stopped, this will teardown all resources.
    systemd.targets."${cfg.backend}-${cfg.rootTargetName}-root" = {
      unitConfig = {
        Description = "Root target for all ${cfg.rootTargetName} resources.";
      };
      wantedBy = [ "multi-user.target" ];
    };
  };

}
