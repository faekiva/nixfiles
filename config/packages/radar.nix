{
  lib,
  stdenv,
  fetchurl,
}:
let
  version = "1.5.11";
  assets = {
    x86_64-darwin = {
      url = "https://github.com/skyhook-io/radar/releases/download/v${version}/radar_v${version}_darwin_amd64.tar.gz";
      hash = "sha256-8leFo8uD/pEnn/IGuVuy029PXxJHtKxbCdmNzyc8ulY=";
    };
    aarch64-darwin = {
      url = "https://github.com/skyhook-io/radar/releases/download/v${version}/radar_v${version}_darwin_arm64.tar.gz";
      hash = "sha256-lPCsLVuXXb1MTrETA3aUFudzMlGDkilOVVMSPeTKT9I=";
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
