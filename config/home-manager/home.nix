{
  pkgs,
  ...
}:
{
  home.stateVersion = "25.11";
  home.packages = [ 
    pkgs.nix-diff
  ];
}
