{
  pkgs,
  ...
}:
{
  imports = ["./level0-packages.nix" "./atuin.nix"];

  home.packages = [ 
    pkgs.nix-diff
    pkgs.gum
    pkgs.lsd
    pkgs.ripgrep
    pkgs.bat
    pkgs.fzf
    pkgs.zsh
  ];
}
