{
  description = "The config for my nix-controlled systems";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";
    nixpkgs-stable.url = "github:NixOS/nixpkgs/nixos-25.11";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";

    determinate.url = "https://flakehub.com/f/DeterminateSystems/determinate/3";
    determinate.inputs.nixpkgs.follows = "nixpkgs";
    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    direnv-instant.url = "github:Mic92/direnv-instant";
    fzf-tab.url = "github:Aloxaf/fzf-tab";
    fzf-tab.flake = false;
    cco.url = "github:nikvdp/cco";
    cco.flake = false;
    llm-agents.url = "github:numtide/llm-agents.nix";

    sops-nix.url = "github:Mic92/sops-nix";
    sops-nix.inputs.nixpkgs.follows = "nixpkgs";

    git-wt.url = "github:ahmedelgabri/git-wt";

    atuin.url = "github:atuinsh/atuin/main";
    atuin.inputs.nixpkgs.follows = "nixpkgs";

    decapod = {
      url = "github:DecapodLabs/decapod";
      flake = false;
    };

    # Nix-index-database - for comma and command-not-found
    nix-index-database = {
      url = "github:nix-community/nix-index-database";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nixpkgs-stable,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      # Get all directory names from a path
      hostDirs =
        path:
        builtins.attrNames (
          nixpkgs.lib.filterAttrs (name: type: type == "directory") (builtins.readDir path)
        );

      darwinHosts = hostDirs ./hosts/Darwin;
      nixosHosts = hostDirs ./hosts/NixOS;

      # Extend inputs with computed values
      inputs' = inputs // {
        flakeRoot = self;
        repoRoot = "${self}/..";
      };

      defaultConstants = import ./modules/constants.nix;
      hostConstants = dir: host:
        let path = ./hosts/${dir}/${host}/constants.nix;
        in if builtins.pathExists path then import path else { };
    in
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.allowUnfreePredicate = _: true;

      nixosConfigurations = builtins.listToAttrs (
        map (host: {
          name = host;
          value = nixpkgs.lib.nixosSystem {
            # system = "x86_64-linux";
            specialArgs = {
              inputs = inputs' // {
                constants = defaultConstants // hostConstants "NixOS" host;
              };
              pkgs-stable = import nixpkgs-stable {
                system = "x86_64-linux";
                config.allowUnfree = true;
              };
            };
            modules = [
              inputs.determinate.nixosModules.default
              ./modules/hereafter/nix-settings.nix
              ./hosts/NixOS/${host}/configuration.nix
              home-manager.nixosModules.home-manager
              inputs.sops-nix.nixosModules.sops
            ];
          };
        }) nixosHosts
      );

      darwinConfigurations = builtins.listToAttrs (
        map (host: {
          name = host;
          value = nix-darwin.lib.darwinSystem {
            specialArgs = {
              inputs = inputs' // {
                constants = defaultConstants // hostConstants "Darwin" host;
              };
            };
            modules = [
              inputs.determinate.darwinModules.default
              ./modules/hereafter/nix-settings-darwin.nix
              ./modules/hereafter/darwin-overlays.nix
              ./hosts/Darwin/${host}/configuration.nix
              home-manager.darwinModules.home-manager
              inputs.sops-nix.darwinModules.sops
            ];
          };
        }) darwinHosts
      );
    };
}
