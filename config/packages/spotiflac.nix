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
    hash = "sha256-1zd8sb1gmcbiy3a472a6as8fb2r7vszx0qvgzksqc7fxbb7w6axg";
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
  # Find the .desktop file (AppImage may name it with different casing)
  desktop_file=$(find ${appimageContents} -name '*.desktop' -type f | head -1)
  if [ -z "$desktop_file" ]; then
    echo "No .desktop file found in AppImage contents"
    exit 1
  fi
  echo "Found desktop file: $desktop_file"

  install -Dm644 ${appimageContents}/spotiflac.png \
    $out/share/icons/hicolor/256x256/apps/spotiflac.png

  install -Dm644 "$desktop_file" \
    $out/share/applications/spotiflac.desktop

  # Fix Exec line and remove TryExec (which hides the app from menus when the path doesn't exist)
  sed -i 's/^Exec=.*/Exec=spotiflac/' $out/share/applications/spotiflac.desktop
  sed -i '/^TryExec=/d' $out/share/applications/spotiflac.desktop
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
