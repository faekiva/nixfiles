{
  pkgs,
  flakeRoot,
  ...
}:
{
  home.packages = [
    pkgs.aider-chat
    (pkgs.callPackage "${flakeRoot}/modules/hereafter/npm/cline-cli.nix" {})
  ];
}
