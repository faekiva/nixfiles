{
  config,
  lib,
  # pkgs,
  # modulesPath,
  ...
}:
{
  options = with lib; {
    hereafter.kvm.users = mkOption {
      type = types.listOf types.str;
      description = "members of the libvirtd group (and anything else kvm related as it comes up).";
    };

  };

  config = {
    programs.virt-manager.enable = true;
    users.groups.libvirtd.members = config.hereafter.kvm.users;
    virtualisation.libvirtd.enable = true;
    virtualisation.spiceUSBRedirection.enable = true;
  };
}
