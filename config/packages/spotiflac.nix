{
  appimageTools,
  fetchurl,
  lib,
}:
let
  pname = "spotiflac";
  version = "7.1.6";

  src = fetchurl {
    url = "https://github.com/spotbye/SpotiFLAC/releases/download/v${version}/SpotiFLAC.AppImage";
    hash = "1zd8sb1gmcbiy3a472a6as8fb2r7vszx0qvgzksqc7fxbb7w6axg";
  };
in
appimageTools.wrapType2 {
  inherit pname version src;

  meta = with lib; {
    description = "Download high quality music from Spotify using Deezer";
    homepage = "https://github.com/spotbye/SpotiFLAC";
    license = licenses.gpl3;
    platforms = [ "x86_64-linux" ];
    mainProgram = "spotiflac";
  };
}
