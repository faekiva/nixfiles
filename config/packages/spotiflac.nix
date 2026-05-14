{
  lib,
  appimageTools,
  fetchurl,
  webkitgtk_4_1,
  ffmpeg,
  glib-networking,
  gst_all_1,
}:

let
  pname = "spotiflac";
  version = "7.1.6";
  src = fetchurl {
    url = "https://github.com/spotbye/SpotiFLAC/releases/download/v${version}/SpotiFLAC.AppImage";
    hash = "1zd8sb1gmcbiy3a472a6as8fb2r7vszx0qvgzksqc7fxbb7w6axg";
  };

  appimageContents = appimageTools.extractType2 { inherit pname version src; };

  runtimeLibs = [
    webkitgtk_4_1
    ffmpeg
  ];

  gstPlugins = with gst_all_1; [
    gstreamer
    gst-plugins-base
    gst-plugins-good
  ];

in
appimageTools.wrapType2 {
  inherit pname version src;

  extraInstallCommands = ''
  install -Dm644 ${appimageContents}/spotiflac.png \
    $out/share/icons/hicolor/256x256/apps/spotiflac.png

  install -Dm644 ${appimageContents}/spotiflac.desktop \
    $out/share/applications/spotiflac.desktop

  substituteInPlace $out/share/applications/spotiflac.desktop \
    --replace-fail 'Exec=SpotiFLAC' 'Exec=spotiflac'
'';

  extraPkgs = pkgs: runtimeLibs ++ gstPlugins;

  extraBwrapArgs = [
    "--setenv" "GIO_EXTRA_MODULES" "${glib-networking}/lib/gio/modules"
    "--setenv" "GST_PLUGIN_PATH" (lib.makeSearchPathOutput "lib" "lib/gstreamer-1.0" gstPlugins)
  ];

  meta = {
    description = "Download high quality music from Spotify using Deezer";
    homepage = "https://github.com/spotbye/SpotiFLAC";
    license = lib.licenses.gpl3;
    platforms = [ "x86_64-linux" ];
    mainProgram = "spotiflac";
  };
}
