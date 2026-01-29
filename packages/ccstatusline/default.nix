{
  lib,
  stdenv,
  fetchzip,
  nodejs,
  makeWrapper,
}:

# Using stdenv.mkDerivation rather than buildNpmPackage because this package
# ships pre-built with zero runtime dependencies (only devDependencies).
# buildNpmPackage's sandboxed npm-deps derivation fails trying to fetch
# devDependencies, and there's no clean way to strip them before that phase runs.
stdenv.mkDerivation rec {
  pname = "ccstatusline";
  version = "2.0.23";

  src = fetchzip {
    url = "https://registry.npmjs.org/ccstatusline/-/ccstatusline-${version}.tgz";
    hash = "sha256-4IlOx+wXPlYqQw14YT1CmxkTLGuST7AR+ozputC9jMs=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    mkdir -p $out/lib/ccstatusline $out/bin
    cp -r . $out/lib/ccstatusline

    makeWrapper ${nodejs}/bin/node $out/bin/ccstatusline \
      --add-flags "$out/lib/ccstatusline/dist/ccstatusline.js"

    runHook postInstall
  '';

  passthru.updateScript = ./update.sh;

  meta = {
    description = "A status line for Claude Code";
    homepage = "https://github.com/sirmalloc/ccstatusline";
    downloadPage = "https://www.npmjs.com/package/ccstatusline";
    license = lib.licenses.mit;
    mainProgram = "ccstatusline";
  };
}
