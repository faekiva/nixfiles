{
  description = "The flake for this repo only (not my config as a whole)";
  inputs.nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";
  inputs.systems.url = "github:nix-systems/default";
  inputs.flake-utils = {
    url = "github:numtide/flake-utils";
    inputs.systems.follows = "systems";
  };
  inputs.compose2nix.url = "github:aksiksi/compose2nix";
  inputs.compose2nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.sops-nix.url = "github:Mic92/sops-nix";
  inputs.sops-nix.inputs.nixpkgs.follows = "nixpkgs";
  inputs.git-hooks.url = "github:cachix/git-hooks.nix";
  inputs.git-hooks.inputs.nixpkgs.follows = "nixpkgs";

  outputs =
    {
      self,
      nixpkgs,
      systems,
      flake-utils,
      compose2nix,
      sops-nix,
      git-hooks,
      ...
    }:
    let
      forEachSystem = nixpkgs.lib.genAttrs (import systems);
    in
    {
      formatter = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          cfg = self.checks.${system}.pre-commit-check.config;
          inherit (cfg) package configFile;
        in
        pkgs.writeShellScriptBin "pre-commit-run" ''
          ${pkgs.lib.getExe package} run --all-files --config ${configFile}
        ''
      );

      checks = forEachSystem (system: {
        pre-commit-check = git-hooks.lib.${system}.run {
          src = ./.;
          hooks.nixfmt.enable = true;
        };
      });

      devShells = forEachSystem (
        system:
        let
          pkgs = nixpkgs.legacyPackages.${system};
          inherit (self.checks.${system}.pre-commit-check) shellHook enabledPackages;
        in
        {
          default = pkgs.mkShell {
            inherit shellHook;
            packages = [
              pkgs.bashInteractive
              pkgs.nixd
              pkgs.nil
              pkgs.nixfmt
              pkgs.nh
              compose2nix.packages.${system}.default
              sops-nix.packages.${system}.default
              pkgs.sops
              pkgs.age
              pkgs.ssh-to-age
              pkgs.curl
              pkgs.jq
              pkgs.perl
              pkgs.go-task
            ]
            ++ enabledPackages;
          };
        }
      );
    };
}
