{
  pkgs,
  ...
}:
{
  home.stateVersion = "25.11";
  home.packages = [
    pkgs.nix-diff
    pkgs.gum
  ];

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
