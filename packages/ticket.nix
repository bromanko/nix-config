{
  lib,
  stdenvNoCC,
  fetchFromGitHub,
  makeWrapper,
  jq,
  ripgrep,
}:

stdenvNoCC.mkDerivation (finalAttrs: {
  pname = "ticket";
  version = "0.3.0";

  src = fetchFromGitHub {
    owner = "wedow";
    repo = "ticket";
    tag = "v${finalAttrs.version}";
    hash = "sha256-3Pwax6QsjaRRASlTkbwxV+wWzw9GCssKGcJqEUnpRKw=";
  };

  nativeBuildInputs = [ makeWrapper ];

  installPhase = ''
    runHook preInstall

    install -Dm755 ticket $out/bin/ticket
    ln -s $out/bin/ticket $out/bin/tk

    wrapProgram $out/bin/ticket \
      --prefix PATH : ${
        lib.makeBinPath [
          jq
          ripgrep
        ]
      }

    runHook postInstall
  '';

  meta = {
    description = "Git-native issue tracker for AI agents";
    homepage = "https://github.com/wedow/ticket";
    license = lib.licenses.mit;
    platforms = lib.platforms.unix;
    mainProgram = "tk";
  };
})
