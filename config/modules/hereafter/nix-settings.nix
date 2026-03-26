{ pkgs, ... }:
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
    # TODO: remove once atuin 18.13.5 lands in nixpkgs-unstable
    (final: prev:
      let
        newSrc = prev.fetchFromGitHub {
          owner = "atuinsh";
          repo = "atuin";
          tag = "v18.13.5";
          hash = "sha256-XOFD7ZvSejNOrXjcR4jBrjimoWC0oNX7DEPN43ACQpE=";
        };
      in
      {
        atuin = prev.atuin.overrideAttrs (old: {
          version = "18.13.5";
          src = newSrc;
          cargoDeps = prev.rustPlatform.fetchCargoVendor {
            src = newSrc;
            name = "atuin-18.13.5-vendor";
            hash = "sha256-4H57Fm6OnA7TaZTfOZeJhsc2s+hZw/MpWAbgtz+L0C4=";
          };
        });
      }
    )
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
