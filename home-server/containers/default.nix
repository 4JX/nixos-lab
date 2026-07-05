{ ... }:

{
  imports = [
    ./nets.nix

    ./lldap

    ./authentik

    ./radarr
    ./sonarr

    ./komga

    ./beszel
    ./blocky
    ./cloudflared
    ./cross-seed
    ./dozzle
    ./flaresolverr
    ./recyclarr
    ./gluetun
    ./jellyfin
    ./prowlarr
    ./qbit_manage
    ./qbittorrent
    ./readarr
    ./suwayomi
    ./swag-internal
    ./swag
    ./thelounge
    ./wg-easy
  ];
}
