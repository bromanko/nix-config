{
  lib,
  stdenvNoCC,
  fetchurl,
  undmg,
}:

stdenvNoCC.mkDerivation rec {
  pname = "codex-app";
  version = "26.422.30944";

  src = fetchurl {
    url = "https://persistent.oaistatic.com/codex-app-prod/Codex.dmg";
    hash = "sha256-kN13FvJgE1t28/Ej+LcFfr57Z720MtAJgyzpDQBcx1M=";
  };

  nativeBuildInputs = [ undmg ];

  sourceRoot = ".";

  # The Codex app bundle is signed. The default fixup phase patches shebangs
  # inside app.asar.unpacked, which invalidates the sealed code signature.
  dontFixup = true;

  unpackPhase = ''
    runHook preUnpack
    undmg "$src"
    runHook postUnpack
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/Applications"
    cp -R "Codex.app" "$out/Applications/Codex.app"

    runHook postInstall
  '';

  meta = {
    description = "Codex desktop app for macOS";
    homepage = "https://developers.openai.com/codex/app";
    license = lib.licenses.unfree;
    platforms = lib.platforms.darwin;
  };
}
