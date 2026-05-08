{ pkgs, lib, ... }:
let
  version = "1.26.3";
  assets = {
    aarch64-darwin = {
      url = "https://go.dev/dl/go${version}.darwin-arm64.tar.gz";
      hash = "sha256-h1z1ShUxHu4smbndZ8aMSkk1HUiatiK/LP0oyPIHjTw=";
    };
    x86_64-darwin = {
      url = "https://go.dev/dl/go${version}.darwin-amd64.tar.gz";
      hash = "sha256-J41YCzLimf5KnJkPzy0CrP5TjH5VGm7hj5xxZFc9LGM=";
    };
    x86_64-linux = {
      url = "https://go.dev/dl/go${version}.linux-amd64.tar.gz";
      hash = "sha256-Kyz8cUhJPaXnOYG/+/M1OvOB1fk+eJyCx5r/ZJYutVY=";
    };
    aarch64-linux = {
      url = "https://go.dev/dl/go${version}.linux-arm64.tar.gz";
      hash = "sha256-nYmj6lfRQcKyLXAIPyyEWbo4kPLZ6Bjn6TO3VhSTZWU=";
    };
  };
  system = pkgs.stdenv.hostPlatform.system;
  asset = assets.${system} or (throw "go: unsupported system ${system}");

  go-bin = pkgs.stdenvNoCC.mkDerivation {
    pname = "go";
    inherit version;

    src = pkgs.fetchurl { inherit (asset) url hash; };

    nativeBuildInputs = lib.optionals pkgs.stdenv.isLinux [
      pkgs.autoPatchelfHook
    ];
    buildInputs = lib.optionals pkgs.stdenv.isLinux [
      pkgs.stdenv.cc.cc.lib
    ];

    dontConfigure = true;
    dontBuild = true;
    dontStrip = true;

    installPhase = ''
      runHook preInstall
      mkdir -p $out/share $out/bin
      cp -r . $out/share/go
      ln -s $out/share/go/bin/go $out/bin/go
      ln -s $out/share/go/bin/gofmt $out/bin/gofmt
      runHook postInstall
    '';
  };
in
{
  home.packages = [ go-bin ];
}
