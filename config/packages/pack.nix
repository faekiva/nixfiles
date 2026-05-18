{
  lib,
  stdenv,
  fetchurl,
}:
let
  version = "0.40.6";
  assets = {
    x86_64-darwin = {
      url = "https://github.com/buildpacks/pack/releases/download/v${version}/pack-v0.40.4-macos.tgz";
      hash = "sha256-ae/E+VqudWd2MssuXxyQiB4rpppVmnHT5pcyu8DXizM=";
    };
    aarch64-darwin = {
      url = "https://github.com/buildpacks/pack/releases/download/v${version}/pack-v0.40.4-macos-arm64.tgz";
      hash = "sha256-nl0VutuNf5KP0jfo4EI+6iOh37O7v0Cj4FyViOJDhIw=";
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
