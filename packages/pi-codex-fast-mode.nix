{
  lib,
  stdenv,
  fetchzip,
}:

# Minimal, dependency-free Pi extension for OpenAI Codex priority processing.
let
  version = "0.2.0";
in
stdenv.mkDerivation {
  pname = "pi-codex-fast-mode";
  inherit version;

  src = fetchzip {
    url = "https://registry.npmjs.org/pi-codex-fast-mode/-/pi-codex-fast-mode-${version}.tgz";
    hash = "sha256-PUyvu2HFYI5V+/PEJFQzE0PMSQK2OhRS8sbEvlKnaBA=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    pkg=$out/lib/pi-codex-fast-mode
    mkdir -p $pkg
    cp -r . $pkg

    runHook postInstall
  '';

  meta = {
    description = "Persistent OpenAI Codex Fast mode extension for Pi";
    homepage = "https://github.com/SI-RUI-ZHANG/pi-codex-fast-mode";
    license = lib.licenses.mit;
  };
}
