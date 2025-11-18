{ ... }:

{
  imports = [
    ./nets.nix

    ./authentik

    ./radarr
    ./sonarr

    ./komga

    ./beszel
    ./cloudflared
    ./cross-seed
    ./dnsmasq
    ./dozzle
    ./flaresolverr
    ./recyclarr
    ./gluetun
    ./jellyfin
    ./jellyseerr
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
