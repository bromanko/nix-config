{
  fetchzip,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "bartender-golden-gate";
  version = "7.0.0-preview.3";

  src = fetchzip {
    url = "https://downloads.macbartender.com/GoldenGate/b7-003.zip";
    hash = "sha256-pWThj0Mf1ZoHv+5xr9nyN6oPfBM4oqtURLgUZHXsXYU=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R "bt-003/Bartender 7.app" "$out/Applications/"

    runHook postInstall
  '';

  # Preserve the upstream app bundle's notarized code signature.
  dontFixup = true;

  meta = {
    description = "Golden Gate preview of the Bartender menu bar organizer";
    homepage = "https://www.macbartender.com/goldengate/";
    downloadPage = "https://www.macbartender.com/goldengate/releases/";
    license = lib.licenses.unfree;
    platforms = lib.platforms.darwin;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
})
