{
  inputs,
  pkgs,
  ...
}:
let
  pack = pkgs.callPackage "${inputs.flakeRoot}/packages/pack.nix" {};
in 
{
  home.stateVersion = "25.11";
  imports = [
    "${inputs.flakeRoot}/modules/hereafter/hm/level1-packages.nix"
    "${inputs.flakeRoot}/modules/hereafter/hm/ai-packages.nix"
    
  ];
  home.packages = [
    pkgs.nickel
    pkgs.nls
    pkgs.ffmpeg-full
    pack
  ];
}
