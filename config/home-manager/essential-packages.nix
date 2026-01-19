{
  pkgs,
  ...
}:
{
  home.packages = [ 
    pkgs.nix-diff
    pkgs.gum
  ];
}
