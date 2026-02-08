{
  pkgs,
  flakeRoot,
  ...
}:
{
  home.stateVersion = "25.11";
  # home.packages  = with pkgs; [

  # ];

  imports = [ 
    "${flakeRoot}/modules/hereafter/hm/level1-packages.nix" 
    "${flakeRoot}/modules/hereafter/hm/ai-packages.nix"
  ];

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
