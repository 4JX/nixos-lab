{ ... }:

{
  virtualisation.oci-containers.networks = [
    { name = "arr"; }
    { name = "exposed"; }
  ];
}
