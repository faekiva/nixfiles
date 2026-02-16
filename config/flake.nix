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

    direnv-instant.url = "github:Mic92/direnv-instant";
  };

  outputs =
    {
      self,
      nixpkgs,
      nix-darwin,
      home-manager,
      direnv-instant,
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
      repoRoot = "${self}/..";
    in
    {
      nixpkgs.config.allowUnfree = true;
      nixpkgs.allowUnfreePredicate = _: true;

      nixosConfigurations = builtins.listToAttrs (map (host: {
        name = host;
        value = nixpkgs.lib.nixosSystem {
          # system = "x86_64-linux";
          specialArgs = { inherit flakeRoot repoRoot direnv-instant; };
          modules = [ ./hosts/NixOS/${host}/configuration.nix home-manager.nixosModules.home-manager ];
        };
      }) nixosHosts);

      darwinConfigurations = builtins.listToAttrs (map (host: {
        name = host;
        specialArgs = { inherit flakeRoot repoRoot direnv-instant; };
        value = nix-darwin.lib.darwinSystem {
          specialArgs = { inherit flakeRoot repoRoot direnv-instant; };
          modules = [ ./hosts/Darwin/${host}/configuration.nix home-manager.darwinModules.home-manager ];
        };
      }) darwinHosts);
    };
}
