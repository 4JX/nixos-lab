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
    mkNetworkService =
      # of type containers.networks
      network: {
        "${backend}-network-${network.name}" = {
          path = [ pkgs.docker ];
          serviceConfig = {
            Type = "oneshot";
            RemainAfterExit = true;
            ExecStop = "${backendBin} network rm -f ${network.name}";
          };
          script = builtins.concatStringsSep " \\\n " (
            [ "${backendBin} network inspect ${network.name} || ${backendBin} network create ${network.name}" ]
            ++ lib.optional (network.subnet != null) "--subnet ${network.subnet}"
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

    # TODO: make part of mkContainer
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
