{
  inputs,
  pkgs,
  ...
}:
{
  home.packages = [
    inputs.direnv-instant.packages.${pkgs.stdenv.hostPlatform.system}.default
  ];

  programs = {
    direnv = {
      enable = true;
      # enableBashIntegration = true; # see note on other shells below
      # enableZshIntegration = true;
      nix-direnv.enable = true;
    };
    # bash.enable = true; # see note on other shells below
    # zsh.enable = true;
  };
}
