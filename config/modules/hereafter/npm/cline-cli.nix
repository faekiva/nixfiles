{
  buildNpmPackage,
  fetchurl,
  ripgrep,
  makeWrapper,
}:

buildNpmPackage (finalAttrs: {
  pname = "cline";
  version = "2.0.5";

  src = fetchurl {
    url = "https://registry.npmjs.org/cline/-/cline-2.0.5.tgz";
    hash = "sha512-yuQw65b4sc8G2CrttMiP+NHM+IEZXgWTZg4nq7koCSPu8+tJlPAX9kaD8Ni/1WoErDoortrQYNGdI5YTV26c9A==";
  };

  postPatch = ''
    cp ${./cline-cli-lock.json} package-lock.json
    # The man page isn't included in the npm tarball
    mkdir -p man
    echo '.TH CLINE 1' > man/cline.1
  '';

  npmDepsHash = "sha256-eP2IRz/Zkd+wYfGC7C9Zz9cW/vd2ICFaiuI07jGEE/Y=";

  # @vscode/ripgrep tries to download a prebuilt binary during postinstall.
  # We skip that and provide system ripgrep via PATH instead.
  npmFlags = [ "--ignore-scripts" ];

  dontNpmBuild = true;

  nativeBuildInputs = [ makeWrapper ];

  postInstall = ''
    wrapProgram $out/bin/cline --prefix PATH : ${ripgrep}/bin
  '';

  meta = {
    description = "Autonomous coding agent CLI - capable of creating/editing files, running commands, using the browser, and more";
  };
})
