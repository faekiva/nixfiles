{
  inputs,
  pkgs,
  ...
}:
{
  home.stateVersion = "25.11";
  home.packages = [
    pkgs.ffmpeg-full
    pkgs.sunshine
    (pkgs.callPackage "${inputs.flakeRoot}/packages/spotiflac.nix" { })
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
