{
  inputs,
  pkgs,
  ...
}:
{
  home.stateVersion = "25.11";
  home.packages = [
    pkgs.ffmpeg-full
  ];

  imports = [
    "${inputs.flakeRoot}/modules/hereafter/hm/level1-packages.nix"
    "${inputs.flakeRoot}/modules/hereafter/hm/ai-packages.nix"
    "${inputs.flakeRoot}/modules/hereafter/hm/beets.nix"
  ];

  dconf.settings = {
    "org/virt-manager/virt-manager/connections" = {
      autoconnect = [ "qemu:///system" ];
      uris = [ "qemu:///system" ];
    };
  };
}
