{
  lib,
  stdenv,
  fetchzip,
  nodejs,
  makeWrapper,
}:

# chrome-devtools-mcp ships pre-built JS with bundled third-party code in build/src,
# so we can package the published npm tarball directly.
stdenv.mkDerivation rec {
  pname = "chrome-devtools-mcp";
  version = "0.20.0";

  src = fetchzip {
    url = "https://registry.npmjs.org/chrome-devtools-mcp/-/chrome-devtools-mcp-${version}.tgz";
    hash = "sha256-tbi5cmrF1m3uI2fgHg5GgbmKhPaamn2dCeKwS8gRe6w=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    pkg=$out/lib/chrome-devtools-mcp
    mkdir -p $pkg $out/bin
    cp -r . $pkg

    makeWrapper ${nodejs}/bin/node $out/bin/chrome-devtools-mcp \
      --add-flags "$pkg/build/src/bin/chrome-devtools-mcp.js"

    makeWrapper ${nodejs}/bin/node $out/bin/chrome-devtools \
      --add-flags "$pkg/build/src/bin/chrome-devtools.js"

    runHook postInstall
  '';

  meta = {
    description = "Chrome DevTools MCP server and CLI";
    homepage = "https://github.com/ChromeDevTools/chrome-devtools-mcp";
    downloadPage = "https://www.npmjs.com/package/chrome-devtools-mcp";
    license = lib.licenses.asl20;
    mainProgram = "chrome-devtools-mcp";
    platforms = lib.platforms.all;
  };
}
