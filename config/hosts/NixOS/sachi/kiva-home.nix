{
  pkgs,
  ...
}:
{
  home.stateVersion = "25.11";
  home.packages  = with pkgs; [
    nix-diff
    gum
    go-task
  ];

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
