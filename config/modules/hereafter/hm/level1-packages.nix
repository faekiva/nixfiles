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
    ./git.nix
    ./go.nix
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
    pkgs.kubectl

    # Brewfile migration
    pkgs.jq
    pkgs.sd
    pkgs.httpie
    pkgs.python313
    pkgs.bun
    pkgs.eget
    pkgs.kubeswitch
    pkgs.mods
    pkgs.postgresql
    rad
  ]
  ++ lib.optional pkgs.stdenv.isDarwin pkgs.coreutils;
}
