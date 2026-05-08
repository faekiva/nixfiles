{
  inputs,
  lib,
  pkgs,
  ...
}:
let
  cco = pkgs.callPackage "${inputs.flakeRoot}/packages/cco.nix" {
    src = inputs.cco;
  };
  kilocode = inputs.llm-agents.packages.${pkgs.system}.kilocode-cli;
  kilocode-with-alias = pkgs.symlinkJoin {
    name = "kilocode-with-alias";
    paths = [ kilocode ];
    nativeBuildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      makeWrapper ${kilocode}/bin/kilocode $out/bin/kilo
    '';
  };
in
{
  home.packages = [
    inputs.llm-agents.packages.${pkgs.system}.claude-code
    # inputs.decapod.packages.${pkgs.system}.default # waiting for new version
    cco
    kilocode-with-alias
    inputs.llm-agents.packages.${pkgs.system}.pi
  ];

  home.file = lib.mapAttrs' (name: _: {
    name = ".pi/agent/extensions/${name}";
    value.source = ./pi-extensions/${name};
  }) (builtins.readDir ./pi-extensions);
}
