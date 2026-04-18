{
  pkgs,
  pkgs-stable,
  inputs,
  ...
}:
{
  home.packages = with pkgs; [
    python312Packages.discogs-client
    python312Packages.flask
    python312Packages.pylast
    python312Packages.requests
    picard
  ];

  programs.beets = {
    enable = true;
    package = pkgs-stable.beets;
    settings = {
      directory = inputs.constants.musicDir;
      library = "${inputs.constants.musicDir}/musiclibrary.blb";
      import.move = true;
      import.log = "${inputs.constants.musicDir}/beets.log";

      plugins = [
        "musicbrainz"
        "fetchart"
        "discogs"
        "ftintitle"
        "fromfilename"
        "inline"
        "rewrite"
        "export"
        "unimported"
      ];

      paths.default = "$albumartist_sort/$album%aunique{} ($original_year) [$format]/%if{$multidisc,Disc $disc/}$track. $title";
      paths.singleton = "Non-Album/$artist/$title";
      paths.comp = "Compilations/$album%aunique{}/$track $title";

      item_fields.multidisc = "1 if disctotal > 1 else 0";

      original_date = false;

      match.preferred = {
        countries = [ "US" "GB|UK" ];
        media = [ "CD" "Digital Media|File" ];
        original_year = true;
      };

      unimported = {
        ignore_extensions = [ "jpg" "png" ];
        ignore_subdirectories = [ "NonMusic" "data" "temp" ];
      };

      musicbrainz = {
        genres = true;
        extra_tags=["ISRC"];
      };
    };
  };
}
