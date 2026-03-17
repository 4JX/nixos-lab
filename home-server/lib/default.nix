{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.local.home-server;

  rootTargetServiceName = "${cfg.backend}-${cfg.rootTargetName}-root.target";

  inherit (cfg) backend;
  backendBin = lib.getExe pkgs.${backend};
in
{
  _module.args.lib' = rec {
    # Returns the name of the systemd service for a given container.
    mkContainerServiceName = containerName: "${backend}-${containerName}.service";

    # Returns { uid, gid, uidStr, gidStr } for a given user/group name,
    getUser =
      userName: groupName:
      let
        inherit (config.users.users.${userName}) uid;
        inherit (config.users.groups.${groupName}) gid;
      in
      {
        inherit uid gid;
        uidStr = builtins.toString uid;
        gidStr = builtins.toString gid;
      };

    mkContainerSecret =
      {
        containerName,
        secretName,
        ...
      }@secret:
      {
        "${secretName}" =
          (builtins.removeAttrs secret [
            "containerName"
            "secretName"
            "restartUnits"
          ])
          // {
            restartUnits = lib.unique (
              (secret.restartUnits or [ ]) ++ [ (mkContainerServiceName containerName) ]
            );
          };
      };

    mkContainerSecrets =
      containerName: secrets:
      lib.mergeAttrsList (
        builtins.map (secret: mkContainerSecret ({ inherit containerName; } // secret)) secrets
      );

    # Like mkContainerSecret but for sops.templates. Auto-adds restartUnits
    # for the container so secret template changes trigger a container restart.
    mkContainerTemplate =
      {
        containerName,
        templateName,
        ...
      }@template:
      {
        "${templateName}" =
          (builtins.removeAttrs template [
            "containerName"
            "templateName"
            "restartUnits"
          ])
          // {
            restartUnits = lib.unique (
              (template.restartUnits or [ ]) ++ [ (mkContainerServiceName containerName) ]
            );
          };
      };

    mkNetworkService =
      # of type containers.networks
      network: {
        "${backend}-network-${network.name}" = {
          path = [ pkgs.${backend} ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStop = "${backendBin} network rm -f ${network.name}";
          };
          script = builtins.concatStringsSep " \\\n " (
            [ "${backendBin} network inspect ${network.name} || ${backendBin} network create ${network.name}" ]
            ++ lib.optional (network.subnet != null) "--subnet ${network.subnet}"
            ++ lib.optional (network.ipRange != null) "--ip-range ${network.ipRange}"
            ++ lib.optional (network.gateway != null) "--gateway ${network.gateway}"
            ++ lib.optional network.internal "--internal"
          );
          partOf = [ rootTargetServiceName ];
          wantedBy = [ rootTargetServiceName ];
        };
      };

    mkNetworkServices =
      networks:
      (lib.pipe networks [
        (builtins.map mkNetworkService)
        lib.mergeAttrsList
      ]);

    mkContainerSystemdService =
      {
        containerName,
        tryRestart,
        networks,
      }:

      let
        networkServiceList = lib.pipe networks [
          # Remove special networks (container:, host:, etc)
          (networks: builtins.filter (n: (builtins.match "^[[:alnum:]]+:.+" n) == null) networks)
          (networks: builtins.map (network: "${backend}-network-${network}.service") networks)
        ];
      in
      {
        name = "${backend}-${containerName}";
        value = {
          serviceConfig =
            if tryRestart then
              {
                Restart = lib.mkOverride 90 "always";
                RestartMaxDelaySec = lib.mkOverride 90 "1m";
                RestartSec = lib.mkOverride 90 "100ms";
                RestartSteps = lib.mkOverride 90 9;
              }
            else
              {
                Restart = lib.mkOverride 90 "no";
              };

          # Networks
          after = networkServiceList;
          requires = networkServiceList;

          # Root target
          partOf = [ rootTargetServiceName ];
          wantedBy = [ rootTargetServiceName ];
        };
      };

    mkContainersSystemdServices =
      containers:
      lib.mapAttrs' (
        name: value:
        mkContainerSystemdService {
          containerName = name;
          inherit (value) tryRestart;
          inherit (value) networks;
        }
      ) containers;
  };
}
