{
  pkgs,
  ...
}:
{
  imports = [./level0-packages.nix ./atuin.nix ./direnv.nix ];

  home.packages = [ 
    pkgs.gum
    pkgs.lsd
    pkgs.ripgrep
    pkgs.bat
    pkgs.fzf
    pkgs.zsh
    pkgs.go-task
  ];
}
