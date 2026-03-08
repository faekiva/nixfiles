{
  pkgs,
  pkgs-stable,
  ...
}:
{
  home.packages = with pkgs; [
    python312Packages.discogs-client
    python312Packages.flask
    python312Packages.pylast
    python312Packages.requests
  ];

  programs.beets = {
    enable = true;
    package = pkgs-stable.beets;
    settings = {
      directory = "/mnt/prodigy/mojo/audio/music/Abarat";
      library = "/mnt/prodigy/mojo/audio/music/Abarat/musiclibrary.blb";
      import.move = true;
      import.log = "/mnt/prodigy/mojo/audio/music/Abarat/beets.log";

      plugins = [
        "lastgenre"
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

      lastgenre = {
        canonical = "";
        source = "album";
        count = 10;
        separator = "; ";
      };

      unimported = {
        ignore_extensions = [ "jpg" "png" ];
        ignore_subdirectories = [ "NonMusic" "data" "temp" ];
      };
    };
  };
}
