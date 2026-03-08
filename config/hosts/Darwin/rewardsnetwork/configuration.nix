{ inputs, pkgs, ... }:
{
  environment.systemPackages = [
    pkgs.git
  ];

  users.users.kiva = {
    name = "khilgenberg";
    home = "/Users/khilgenberg";
  };

  home-manager.extraSpecialArgs = { inherit inputs; };
  home-manager.users.kiva = ./kiva-home.nix;
  home-manager.useGlobalPkgs = true;
  nixpkgs.config.allowUnfree = true;

  # Enable alternative shell support in nix-darwin.
  # programs.fish.enable = true;

  # Set Git commit hash for darwin-version.
  system.configurationRevision = inputs.flakeRoot.rev or inputs.flakeRoot.dirtyRev or null;

  # Used for backwards compatibility, please read the changelog before changing.
  # $ darwin-rebuild changelog
  system.stateVersion = 6;

  # The platform the configuration will be used on.
  nixpkgs.hostPlatform = "aarch64-darwin";
}

# List packages installed in system profile. To search by name, run:
# $ nix-env -qaP | grep wget
