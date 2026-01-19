{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";

    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # Home manager
    home-manager = {
      url = "github:nix-community/home-manager/release-25.11";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
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
      flakeRoot = self;
    in
    {
      nixosConfigurations = builtins.listToAttrs (map (host: {
        name = host;
        specialArgs = { inherit flakeRoot; };
        value = nixpkgs.lib.nixosSystem {
          system = "x86_64-linux";
          specialArgs = { inherit flakeRoot; };
          modules = [ ./hosts/NixOS/${host}/configuration.nix home-manager.nixosModules.home-manager ];
        };
      }) nixosHosts);

      darwinConfigurations = builtins.listToAttrs (map (host: {
        name = host;
        value = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit flakeRoot; };
          modules = [ ./hosts/Darwin/${host}/configuration.nix home-manager.darwinModules.home-manager ];
        };
      }) darwinHosts);
    };
}
