{
  lib,
  stdenv,
  makeWrapper,
  src,
}:
stdenv.mkDerivation {
  pname = "cco";
  version = "unstable";

  inherit src;

  nativeBuildInputs = [ makeWrapper ];

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/cco $out/bin
    cp cco sandbox $out/lib/cco/
    cp -r lib $out/lib/cco/
    chmod +x $out/lib/cco/cco $out/lib/cco/sandbox
    makeWrapper $out/lib/cco/cco $out/bin/cco

    runHook postInstall
  '';

  meta = with lib; {
    description = "A lightweight sandboxing wrapper for Claude Code";
    homepage = "https://github.com/nikvdp/cco";
    license = licenses.mit;
    platforms = platforms.unix;
    mainProgram = "cco";
  };
}
