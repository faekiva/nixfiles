{ pkgs, inputs, ... }:
{
  nixpkgs.overlays = [
    # TODO: remove once https://github.com/NixOS/nixpkgs/pull/486452 lands in nixpkgs-unstable
    (final: prev: {
      direnv = prev.direnv.overrideAttrs (old: {
        postPatch = (old.postPatch or "") + ''
          substituteInPlace GNUmakefile --replace-fail " -linkmode=external" ""
        '';
      });
    })
    inputs.atuin.overlays.default
  ];

  nix.package = pkgs.lixPackageSets.stable.lix;

  nix.settings = {
    experimental-features = [
      "nix-command"
      "flakes"
    ];
    extra-substituters = [ "https://cache.numtide.com" ];
    extra-trusted-public-keys = [ "niks3.numtide.com-1:DTx8wZduET09hRmMtKdQDxNNthLQETkc/yaX7M4qK0g=" ];
    accept-flake-config = false;
  };
}
