{
  lib,
  stdenv,
  fetchzip,
}:

# Pi extension package fetched from npm.
let
  version = "2.2.0";
in
stdenv.mkDerivation {
  pname = "pi-claude-code-use";
  inherit version;

  src = fetchzip {
    url = "https://registry.npmjs.org/@benvargas/pi-claude-code-use/-/pi-claude-code-use-${version}.tgz";
    hash = "sha256-kg6djtAi5yJ2EhAekphiQ0aJQ1R/eWvaDIWOhCxzzzw=";
  };

  dontBuild = true;

  installPhase = ''
    runHook preInstall

    pkg=$out/lib/pi-claude-code-use
    mkdir -p $pkg

    cp -r . $pkg

    runHook postInstall
  '';

  meta = {
    description = "Patch Anthropic OAuth payloads for Claude Code-style subscription use in Pi";
    homepage = "https://github.com/ben-vargas/pi-packages/tree/main/packages/pi-claude-code-use";
    license = lib.licenses.mit;
  };
}
