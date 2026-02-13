{
  pkgs,
  flakeRoot,
  ...
}:
{
  home.stateVersion = "25.11";
  home.packages = [
    pkgs.ffmpeg-full
  ];

  imports = [ 
    "${flakeRoot}/modules/hereafter/hm/level1-packages.nix" 
    "${flakeRoot}/modules/hereafter/hm/ai-packages.nix"
    "${flakeRoot}/modules/hereafter/prodigy-mounts.nix"
  ];

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
