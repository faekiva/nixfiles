{
  lib,
  stdenv,
  fetchurl,
}:
let
  version = "0.40.6";
  assets = {
    x86_64-darwin = {
      url = "https://github.com/buildpacks/pack/releases/download/v${version}/pack-v${version}-macos.tgz";
      hash = "sha256-AUyNj6ar7u5yhZTZ2v9TjeIkwf5WObUFeme3q0hE8P4=";
    };
    aarch64-darwin = {
      url = "https://github.com/buildpacks/pack/releases/download/v${version}/pack-v${version}-macos-arm64.tgz";
      hash = "sha256-kJb+0ZCPKVeah8BfRRUzKt6xGncQGvq46DZZf9sKsao=";
    };
  };
  asset =
    assets.${stdenv.hostPlatform.system} or (throw "unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "pack";
  inherit version;

  src = fetchurl {
    inherit (asset) url hash;
  };

  sourceRoot = ".";

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m755 pack $out/bin/pack

    runHook postInstall
  '';

  meta = with lib; {
    description = "";
    homepage = "https://github.com/buildpacks/pack";
    license = licenses.asl20;
    platforms = [
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "pack";
  };
}
