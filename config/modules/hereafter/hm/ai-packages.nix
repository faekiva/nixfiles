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
    (pkgs.rustPlatform.buildRustPackage rec {
      pname = "decapod";
      version = "0.47.27";

      src = inputs.decapod;

      cargoLock.lockFile = "${inputs.decapod}/Cargo.lock";

      nativeBuildInputs = with pkgs; [
        pkg-config
      ];

      buildInputs = with pkgs; [
        sqlite
      ];

      # Remove .cargo/config.toml which forces clang+lld (not needed with Nix's cc)
      postPatch = ''
        rm -f .cargo/config.toml
      '';

      # These tests are designed around the upstream repo's own internal
      # consistency (doc hashes, KCR trend counts, artifact manifests, etc.)
      # and fail due to stale data and patching in the Nix build
      doCheck = false;

      meta = {
        description = "Daemonless, local-first control plane for multi-agent work";
        homepage = "https://github.com/DecapodLabs/decapod";
        license = pkgs.lib.licenses.mit;
        mainProgram = "decapod";
      };
    })
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
