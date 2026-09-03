{
  fetchzip,
  lib,
  stdenvNoCC,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "bartender-golden-gate";
  version = "7.0.0-beta.1";

  src = fetchzip {
    url = "https://downloads.macbartender.com/GoldenGate/bt7-b1.zip";
    hash = "sha256-cwMO/5qEeM3r9ny/Kk3QHSuyWG721rAhx3bUm7Ho2JY=";
    stripRoot = false;
  };

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R "bt7-b1/Bartender 7.app" "$out/Applications/"

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
