{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.local.home-server;

  rootTargetServiceName = "${cfg.backend}-${cfg.rootTargetName}-root.target";

  backend = cfg.backend;
  backendBin = lib.getExe pkgs.${backend};
in
{
  _module.args.lib' = {
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
          script = "${backendBin} network inspect ${network.name} || ${backendBin} network create ${network.name} ${
            lib.optionalString (network.subnet != null) "--subnet ${network.subnet}"
          } ${lib.optionalString (network.internal) "--internal"}";
          partOf = [ rootTargetServiceName ];
          wantedBy = [ rootTargetServiceName ];
        };
      };

    # TODO: make part of mkContainer
    mkContainerSystemdService =
      {
        containerName,
        tryRestart,
        networks,
      }:

      let
        networkServiceList = builtins.map (network: "${backend}-network-${network}.service") networks;
      in
      {
        "${backend}-${containerName}" = {
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
  };
}
