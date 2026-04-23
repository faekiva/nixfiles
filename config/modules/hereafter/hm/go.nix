{ pkgs, ... }:
{
  home.packages = [
    (pkgs.go.overrideAttrs {
      version = "1.26.2";
      src = pkgs.fetchurl {
        url = "https://go.dev/dl/go1.26.2.src.tar.gz";
        hash = "sha256-LpHrtpR6lulDb7KzkmqIAu/mOm03Xf/sT4Kqnb1v1Ds=";
      };
    })
  ];
}
