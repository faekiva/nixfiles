{
  lib,
  stdenv,
  fetchurl,
  autoPatchelfHook,
}:
let
  version = "0.10.1";
  assets = {
    x86_64-linux = {
      url = "https://github.com/amterp/rad/releases/download/v${version}/rad_linux_amd64.tar.gz";
      hash = "sha256-yHrcLo5wprY3T77zXienIO2XaZxNXpEWpAdX0XEqTv0=";
    };
    aarch64-linux = {
      url = "https://github.com/amterp/rad/releases/download/v${version}/rad_linux_arm64.tar.gz";
      hash = "sha256-jzWcI5m6g0MTRPv8WaaPAj+nLR7zB1lFqKEytj8pkjI=";
    };
    x86_64-darwin = {
      url = "https://github.com/amterp/rad/releases/download/v${version}/rad_darwin_amd64.tar.gz";
      hash = "sha256-Xi7gdSBRQvWzhO5xb8tkutTLq2/bAich/BZc2nRIAQY=";
    };
    aarch64-darwin = {
      url = "https://github.com/amterp/rad/releases/download/v${version}/rad_darwin_arm64.tar.gz";
      hash = "sha256-r9euxAjSEZoooBBlsaVKXnEopCE3mFjfuDBSF6DvWdY=";
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
