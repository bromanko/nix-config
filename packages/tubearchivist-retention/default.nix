{
  lib,
  python3,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation {
  pname = "tubearchivist-retention";
  version = "1.0.0";
  src = ./.;

  nativeBuildInputs = [ python3 ];

  doCheck = true;
  checkPhase = ''
    runHook preCheck
    python -m unittest -v test_retention.py
    runHook postCheck
  '';

  installPhase = ''
    runHook preInstall
    install -Dm755 retention.py $out/bin/tubearchivist-retention
    substituteInPlace $out/bin/tubearchivist-retention \
      --replace-fail '#!/usr/bin/env python3' '#!${python3}/bin/python3'
    runHook postInstall
  '';

  meta = {
    description = "Enforce a size limit through the TubeArchivist API";
    license = lib.licenses.mit;
    mainProgram = "tubearchivist-retention";
    platforms = lib.platforms.unix;
  };
}
