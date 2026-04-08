{ pkgs, inputs, ... }:
let
  pkgs-stable = import inputs.nixpkgs-stable { inherit (pkgs) system; };
in
{
  nix.package = pkgs-stable.lixPackageSets.stable.lix;

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
