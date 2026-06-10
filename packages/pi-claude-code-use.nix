{
  lib,
  stdenv,
  fetchzip,
}:

# Pi extension package fetched from npm with its runtime dependency assembled manually.
let
  version = "1.0.4";

  jiti = fetchzip {
    url = "https://registry.npmjs.org/@mariozechner/jiti/-/jiti-2.6.5.tgz";
    hash = "sha256-L4dBQkBs2C2to79qoQaRfJ8afyQBFVYTUYEEjAdHuh8=";
  };
in
stdenv.mkDerivation {
  pname = "pi-claude-code-use";
  inherit version;

  src = fetchzip {
    url = "https://registry.npmjs.org/@benvargas/pi-claude-code-use/-/pi-claude-code-use-${version}.tgz";
    hash = "sha256-z60aDjpd8+sUDwdPfNlVpCpxROaV3bQ5Hh7v1rJG43c=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    pkg=$out/lib/pi-claude-code-use
    mkdir -p $pkg/node_modules/@mariozechner

    cp -r . $pkg
    ln -s ${jiti} $pkg/node_modules/@mariozechner/jiti

    runHook postInstall
  '';

  meta = {
    description = "Patch Anthropic OAuth payloads for Claude Code-style subscription use in Pi";
    homepage = "https://github.com/ben-vargas/pi-packages/tree/main/packages/pi-claude-code-use";
    license = lib.licenses.mit;
  };
}
