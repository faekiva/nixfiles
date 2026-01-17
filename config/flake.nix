{
  description = "A very basic flake";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-25.11";


    nix-darwin.url = "github:nix-darwin/nix-darwin/nix-darwin-25.11";
    nix-darwin.inputs.nixpkgs.follows = "nixpkgs";
    # Home manager
    # home-manager = {
    #   url = "github:nix-community/home-manager";
    #   inputs.nixpkgs.follows = "nixpkgs";
    # };
  };

  outputs = { self, nixpkgs, nix-darwin }: {

   nixosConfigurations.sachi = nixpkgs.lib.nixosSystem {
      # NOTE: Change this to aarch64-linux if you are on ARM
      system = "x86_64-linux";
      modules = [ ./hosts/sachi/configuration.nix ];
    };
    darwinConfigurations.batgirl = nix-darwin.lib.darwinSystem {
      inherit self;
      modules = [ ./hosts/batgirl/configuration.nix ];
    };
  };
}
