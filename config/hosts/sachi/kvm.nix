{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
{
  programs.virt-manager.enable = true;
  users.groups.libvirtd.members = [ "kiva" ];
  virtualisation.libvirtd.enable = true;
  virtualisation.spiceUSBRedirection.enable = true;
}
