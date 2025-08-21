{ config, ... }:

{
  users.groups = {
    dockergeneral.gid = 10110;
    dockermedia.gid = 10120;
    dockerproxy.gid = 10130;
    dockersocket.gid = 10140;
    dockerauth.gid = 10150;
  };

  users.users = {
    dockergeneral = {
      uid = 10110;
      group = config.users.groups.dockergeneral.name;
      isSystemUser = true;
      shell = "/usr/sbin/nologin";
    };
    dockermedia = {
      uid = 10120;
      group = config.users.groups.dockermedia.name;
      isSystemUser = true;
      shell = "/usr/sbin/nologin";
    };
    dockerproxy = {
      uid = 10130;
      group = config.users.groups.dockerproxy.name;
      isSystemUser = true;
      shell = "/usr/sbin/nologin";
    };
    dockersocket = {
      uid = 10140;
      group = config.users.groups.dockersocket.name;
      isSystemUser = true;
      shell = "/usr/sbin/nologin";
    };
    dockerauth = {
      uid = 10150;
      group = config.users.groups.dockerauth.name;
      isSystemUser = true;
      shell = "/usr/sbin/nologin";
    };
  };

  systemd.tmpfiles.settings = {
    # - d: create directory if missing
    # - Z: recursively enforce owner/group/mode at boot (fix drift)

    "00-containers" = {
      # /containers: root-owned, traversable only
      "/containers" = {
        d = {
          mode = "0711";
          user = "root";
          group = "root";
        };
      };

      # /containers/config: root-owned, traversable only
      "/containers/config" = {
        d = {
          mode = "0711";
          user = "root";
          group = "root";
        };
      };

      # /containers/mediaserver: shared by media containers
      "/containers/mediaserver" = {
        d = {
          mode = "2775";
          user = config.users.users.dockermedia.name;
          group = config.users.groups.dockermedia.name;
        };
        Z = {
          mode = "2775";
          user = config.users.users.dockermedia.name;
          group = config.users.groups.dockermedia.name;
        };
      };

      # /containers/authentik: dedicated Authentik area
      "/containers/authentik" = {
        d = {
          mode = "2770";
          user = config.users.users.dockerauth.name;
          group = config.users.groups.dockerauth.name;
        };
        # Z = {
        #   mode = "2770";
        #   user = config.users.users.dockerauth.name;
        #   group = config.users.groups.dockerauth.name;
        # };
      };
    };
  };
}
