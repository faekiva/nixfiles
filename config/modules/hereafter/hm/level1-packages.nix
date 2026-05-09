{
  pkgs,
  lib,
  inputs,
  ...
}:
let
  rad = pkgs.callPackage "${inputs.flakeRoot}/packages/rad.nix" { };
  radar = pkgs.callPackage "${inputs.flakeRoot}/packages/radar.nix" { };
  # Shadow the system nix zsh on Darwin: the prebuilt binary (built against
  # an older Darwin SDK) hangs on $(...) under interactive mode. Apple's
  # /bin/zsh is unaffected. Home-manager profile beats system profile in
  # PATH, so this symlink wins for `which zsh` / `exec zsh`.
  zshSystem = pkgs.runCommand "zsh-system" { } ''
    mkdir -p $out/bin
    ln -s /bin/zsh $out/bin/zsh
  '';
in
{
  imports = [
    ./level0-packages.nix
    ./atuin.nix
    ./direnv.nix
    ./git.nix
    ./go.nix
    ./tmux.nix
  ];

  home.packages = [
    pkgs.gum
    pkgs.dust
    pkgs.lsd
    pkgs.ripgrep
    pkgs.bat
    pkgs.fzf
    pkgs.go-task
    pkgs.gh
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
  ++ lib.optional pkgs.stdenv.isDarwin pkgs.coreutils
  ++ lib.optional pkgs.stdenv.isDarwin zshSystem
  ++ lib.optional pkgs.stdenv.isDarwin radar;
}
