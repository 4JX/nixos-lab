{ ... }:

{
  virtualisation.oci-containers.networks = [
    { name = "arr"; }
    { name = "exposed"; }
    {
      name = "ldap";
      internal = true;
    }
    { name = "lldap"; }
  ];
}
