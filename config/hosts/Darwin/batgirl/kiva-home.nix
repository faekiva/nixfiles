{
  pkgs,
  flakeRoot,
  ...
}:
{
  home.stateVersion = "25.11";
  imports =  ["${flakeRoot}/modules/hereafter/hm/level1-packages.nix" {inherit flakeRoot;}];
}
