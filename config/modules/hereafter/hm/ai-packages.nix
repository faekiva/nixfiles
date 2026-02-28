{
  inputs,
  pkgs,
  ...
}:
let
  cco = pkgs.callPackage "${inputs.flakeRoot}/packages/cco.nix" {
    src = inputs.cco;
  };
in
{
  home.packages = [
    pkgs.aider-chat
    pkgs.claude-code
    cco
  ];
}
