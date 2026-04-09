{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
let
  version = "0.9.2";
  assets = {
    x86_64-linux = {
      url = "https://github.com/amterp/rad/releases/download/v${version}/rad_linux_amd64.tar.gz";
      hash = "sha256:02a4430696cfdd0bf152b9f943b6365f5dcde2e571db70bffe5ab2ee4a7b64c1";
    };
    aarch64-linux = {
      url = "https://github.com/amterp/rad/releases/download/v${version}/rad_linux_arm64.tar.gz";
      hash = "sha256:f6e2fc596159b4301aac93ef234428904790d300883f235efbfe9cc9b5edfbb4";
    };
    x86_64-darwin = {
      url = "https://github.com/amterp/rad/releases/download/v${version}/rad_darwin_amd64.tar.gz";
      hash = "sha256:24066515b843b18cc7a5ae029d7aa5a4781d3c2a9c0f5d59d993a8ada8a0ab3f";
    };
    aarch64-darwin = {
      url = "https://github.com/amterp/rad/releases/download/v${version}/rad_darwin_arm64.tar.gz";
      hash = "sha256:5f3ee89b614526bf82547fdf97d0d311e848d2904f9878df888d2d41461c17cb";
    };
  };
  asset =
    assets.${stdenv.hostPlatform.system} or (throw "unsupported system: ${stdenv.hostPlatform.system}");
in
stdenv.mkDerivation {
  pname = "rad";
  inherit version;

  src = fetchurl {
    inherit (asset) url hash;
  };

  sourceRoot = ".";

  nativeBuildInputs = lib.optional stdenv.isLinux autoPatchelfHook;

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/bin
    install -m755 rad $out/bin/rad
    install -m755 radls $out/bin/radls

    runHook postInstall
  '';

  meta = with lib; {
    description = "A general-purpose scripting language";
    homepage = "https://github.com/amterp/rad";
    license = licenses.asl20;
    platforms = [
      "x86_64-linux"
      "aarch64-linux"
      "x86_64-darwin"
      "aarch64-darwin"
    ];
    mainProgram = "rad";
  };
}
