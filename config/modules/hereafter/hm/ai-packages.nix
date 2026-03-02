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
    inputs.llm-agents.packages.${pkgs.system}.claude-code
    cco
    inputs.llm-agents.packages.${pkgs.system}.kilocode-cli
  ];
}
