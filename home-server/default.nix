# Do I need this? https://github.com/rasmus-kirk/nixarr?tab=readme-ov-file
# Nice inspiration: https://github.com/painerp/nixos/blob/339554807b155d54b1e9a996d9693fec77d86f39/containers/gluetun.nix

# Alternatively for containers:
# https://github.com/hercules-ci/arion
# https://nixos.wiki/wiki/NixOS_Containers

{
  lib,
  lib',
  config,
  options,
  pkgs,
  ...
}:

let
  cfg = config.local.home-server;
  ociCfg = config.virtualisation.oci-containers;
  # systemUsers = lib.attrNames config.users.users;

  extraContainerOpts = {
    options = {
      tryRestart = mkOption {
        type = types.bool;
        default = true;
        description = "Whether to try to restart the container on failure.";
      };
    };
  };

  inherit (lib) mkOption mkEnableOption types;
in
{
  imports = [
    ./lib

    ./containers

    ./ddns

    ./nvidia-ctk.nix
    ./permissions.nix
    ./tor.nix
  ];

  options = {
    local.home-server = {
      enable = mkEnableOption "the home-server module" // {
        enable = true;
      };
      secretsFolder = mkOption {
        type = types.path;
        default = ../secrets/hs;
        description = "The path to the home-server secrets folder.";
      };
      rootTargetName = mkOption {
        type = types.str;
        default = "home-server";
        description = "The name of the root target.";
      };
      backend = options.virtualisation.oci-containers.backend // {
        default = "docker";
      };
    };
    virtualisation.oci-containers = {
      containers = mkOption {
        type = with types; attrsOf (submodule extraContainerOpts);
      };
      networks = mkOption {
        type = types.listOf (
          types.submodule {
            options = {
              name = mkOption {
                type = types.str;
                description = "Name of the network used by containers.";
                example = "mynetwork";
              };
              subnet = mkOption {
                type = with types; nullOr str;
                default = null;
                description = "Subnet of the network user by containers.";
                example = "172.30.0.0/16";
              };
              internal = mkOption {
                type = types.bool;
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

    systemd.services =
      # Container services
      (lib'.mkContainersSystemdServices ociCfg.containers)
      # Container networks
      // (lib'.mkNetworkServices ociCfg.networks);

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
