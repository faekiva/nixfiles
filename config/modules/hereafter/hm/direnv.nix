{
  inputs,
  pkgs,
  ...
}:
{
  imports = [
    inputs.direnv-instant.homeModules.direnv-instant
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

    direnv-instant = {
      enable = true;
    };
  };
}
