{ ... }:

{
  local.home-server.containers.networks = [
    { name = "arr"; }
    { name = "exposed"; }
    { name = "thelounge"; }
    # HACK: Create a custom network for the wireguard server because for some reason other network subnets
    # become unreachable if the container is just assigned to the existing networks where containers already exist.
    # Use "0" as a prefix to have it get chosen as the one to get an IP from by docker.
    { name = "0wireguard"; }
    { name = "dozzle"; }
    { name = "socket-proxy-dozzle"; }
    { name = "komga"; }
  ];
}
