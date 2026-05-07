{
  lib,
  stdenv,
  fetchurl,
}:
let
  version = "1.5.10";
  assets = {
    x86_64-darwin = {
      url = "https://github.com/skyhook-io/radar/releases/download/v${version}/radar_v${version}_darwin_amd64.tar.gz";
      hash = "sha256:da325f28d30e781b2da39d6479a6df8143f0500f0c457d0f4b8f69645366d11d";
    };
    aarch64-darwin = {
      url = "https://github.com/skyhook-io/radar/releases/download/v${version}/radar_v${version}_darwin_arm64.tar.gz";
      hash = "sha256:73de9c79dacd4bde29816ecebb713e6ef83e580e553dc24acc0b334ed9694885";
    };
  };
  asset =
    assets.${stdenv.hostPlatform.system} or (throw "unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "radar";
  inherit version;

  src = fetchurl {
    inherit (asset) url hash;
  };

  sourceRoot = ".";

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m755 kubectl-radar $out/bin/kubectl-radar
    ln -s kubectl-radar $out/bin/radar

    runHook postInstall
  '';

  meta = with lib; {
    description = "Skyhook Radar CLI for Kubernetes";
    homepage = "https://github.com/skyhook-io/radar";
    license = licenses.asl20;
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "radar";
  };
}
