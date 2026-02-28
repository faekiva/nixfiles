{
  description = "A basic flake with a shell";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  inputs.systems.url = "github:nix-systems/default";
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.systems.follows = "systems";
  };
  inputs.compose2nix.url = "github:aksiksi/compose2nix";
  inputs.compose2nix.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    { nixpkgs, flake-utils, compose2nix, ... }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShells.default = pkgs.mkShell { 
          packages = [
            pkgs.bashInteractive
            pkgs.nixd
            pkgs.nixfmt
            pkgs.nh
            compose2nix.packages.${system}.default
          ]; 
        };
      }
    );
}
