{
  inputs,
  lib,
  pkgs,
  ...
}:
# let
  # cco = pkgs.callPackage "${inputs.flakeRoot}/packages/cco.nix" {
  #   src = inputs.cco;
  # };
  # kilocode = inputs.llm-agents.packages.${pkgs.system}.kilocode-cli;
  # kilocode-with-alias = pkgs.symlinkJoin {
  #   name = "kilocode-with-alias";
  #   paths = [ kilocode ];
  #   nativeBuildInputs = [ pkgs.makeWrapper ];
  #   postBuild = ''
  #     makeWrapper ${kilocode}/bin/kilocode $out/bin/kilo
  #   '';
  # };
# in
{
  home.packages = [
    inputs.llm-agents.packages.${pkgs.system}.claude-code
    inputs.decapod.packages.${pkgs.system}.default
    # cco
    # kilocode-with-alias
    inputs.llm-agents.packages.${pkgs.system}.pi
  ];

  home.file.".pi/agent" = {
    source = ./.pi/agent;
    recursive = true;
  };

  home.activation.removePiAgentSymlink = lib.hm.dag.entryBefore [ "linkGeneration" ] ''
    if [ -L "$HOME/.pi/agent" ]; then
      rm "$HOME/.pi/agent"
    fi
  '';
}
