{
  config,
  lib,
  pkgs,
  ...
}:

let
  cfg = config.local.home-server;

  rootTargetServiceName = "${cfg.backend}-${cfg.rootTargetName}-root.target";
in
{
  _module.args.lib' = {
    mkNetworkService =
      # of type containers.networks
      network:
      let
        backend = cfg.backend;
        backendBin = lib.getExe pkgs."${backend}";
      in
      {
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
  };
}
