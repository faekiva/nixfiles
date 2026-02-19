{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixpkgs-unstable";

    nix-darwin.url = "github:nix-darwin/nix-darwin/master";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/master";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    direnv-instant.url = "github:faekiva/direnv-instant/iterm2";
    fzf-tab.url = "github:Aloxaf/fzf-tab";
    fzf-tab.flake = false;
  };

  outputs =
    inputs@{
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      ...
    }:
    let
      # Get all directory names from a path
      hostDirs = path:
        builtins.attrNames (
          nixpkgs.lib.filterAttrs
            (name: type: type == "directory")
            (builtins.readDir path)
        );

      darwinHosts = hostDirs ./hosts/Darwin;
      nixosHosts = hostDirs ./hosts/NixOS;

      # Extend inputs with computed values
      inputs' = inputs // {
        flakeRoot = self;
        repoRoot = "${self}/..";
      };
    in
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.allowUnfreePredicate = _: true;

      nixosConfigurations = builtins.listToAttrs (map (host: {
        name = host;
        value = nixpkgs.lib.nixosSystem {
          # system = "x86_64-linux";
          specialArgs = { inputs = inputs'; };
          modules = [ ./hosts/NixOS/${host}/configuration.nix home-manager.nixosModules.home-manager ];
        };
      }) nixosHosts);

      darwinConfigurations = builtins.listToAttrs (map (host: {
        name = host;
        value = nix-darwin.lib.darwinSystem {
          specialArgs = { inputs = inputs'; };
          modules = [ ./hosts/Darwin/${host}/configuration.nix home-manager.darwinModules.home-manager ];
        };
      }) darwinHosts);
    };
}
