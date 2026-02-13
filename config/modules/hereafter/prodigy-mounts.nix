{
  config,
  lib,
  # pkgs,
  # modulesPath,
  ...
}:
{
  fileSystems = {
    "/mnt/prodigy/mojo" = {
      fsType = "nfs";
      device = "192.168.8.127:/volume1/Mojo";
      options = [ "suid" "dev" "exec" "auto" "nouser" "async" ];
    };
  }
  ;
}
