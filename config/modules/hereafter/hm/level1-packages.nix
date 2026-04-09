{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  rad = pkgs.callPackage "${inputs.flakeRoot}/packages/rad.nix" { };
in
{
  imports = [
    ./level0-packages.nix
    ./atuin.nix
    ./direnv.nix
  ];

  home.packages = [
    pkgs.gum
    pkgs.dust
    pkgs.lsd
    pkgs.ripgrep
    pkgs.bat
    pkgs.fzf
    pkgs.zsh
    pkgs.go-task
    pkgs.tmux
    inputs.git-wt.packages.${pkgs.system}.default

    # Brewfile migration
    pkgs.delta
    pkgs.jq
    pkgs.sd
    pkgs.httpie
    pkgs.python313
    pkgs.go
    pkgs.bun
    pkgs.eget
    pkgs.kubeswitch
    pkgs.mods
    rad
  ]
  ++ lib.optional pkgs.stdenv.isDarwin pkgs.coreutils;
}
