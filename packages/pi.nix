{
  fd,
  fetchurl,
  lib,
  makeWrapper,
  patchelf,
  ripgrep,
  stdenv,
  stdenvNoCC,
  versionCheckHook,
}:

let
  version = "0.84.4";
  releases = {
    aarch64-darwin = {
      asset = "pi-darwin-arm64.tar.gz";
      hash = "sha256-xo46xNBbTigqqrLmx28WHT6eaPGaIuOJE8v6rbbIAPA=";
    };
    x86_64-darwin = {
      asset = "pi-darwin-x64.tar.gz";
      hash = "sha256-egQtZBMGVCE4cAGkmGGQoaAxhslaaV9N7gvcduYN6Pc=";
    };
    aarch64-linux = {
      asset = "pi-linux-arm64.tar.gz";
      hash = "sha256-E1WA9rlCFRZG5nuLhm2YfSjOPP9aSXAwd13dKWWflD0=";
    };
    x86_64-linux = {
      asset = "pi-linux-x64.tar.gz";
      hash = "sha256-wvPD5qGFC9h2VMw8qIEQEycjl8PQQqTipkxD7htCOXI=";
    };
  };
  release =
    releases.${stdenvNoCC.hostPlatform.system}
      or (throw "unsupported Pi platform: ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "pi";
  inherit version;

  src = fetchurl {
    url = "https://github.com/earendil-works/pi/releases/download/v${version}/${release.asset}";
    inherit (release) hash;
  };

  strictDeps = true;
  dontConfigure = true;
  dontBuild = true;

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [
    patchelf
  ];
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  # Pi is a Bun standalone executable. ELF rewriting and stripping remove its
  # embedded application payload and leave a plain Bun runtime behind.
  dontPatchELF = true;
  dontStrip = true;

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin" "$out/libexec"
    cp -R . "$out/libexec/pi"

    ${
      if stdenvNoCC.hostPlatform.isLinux then
        ''
          makeWrapper "${stdenv.cc.bintools.dynamicLinker}" "$out/bin/pi" \
            --add-flags "$out/libexec/pi/pi" \
            --prefix PATH : ${
              lib.makeBinPath [
                fd
                ripgrep
              ]
            } \
            --set PI_PACKAGE_DIR "$out/libexec/pi" \
            --set PI_SKIP_VERSION_CHECK 1 \
            --set PI_TELEMETRY 0
        ''
      else
        ''
          makeWrapper "$out/libexec/pi/pi" "$out/bin/pi" \
            --prefix PATH : ${
              lib.makeBinPath [
                fd
                ripgrep
              ]
            } \
            --set PI_PACKAGE_DIR "$out/libexec/pi" \
            --set PI_SKIP_VERSION_CHECK 1 \
            --set PI_TELEMETRY 0
        ''
    }

    runHook postInstall
  '';

  postFixup = lib.optionalString stdenvNoCC.hostPlatform.isLinux ''
    while IFS= read -r -d "" addon; do
      patchelf \
        --set-rpath ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]} \
        "$addon"
    done < <(find "$out/libexec/pi" -type f -name '*.node' -print0)
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];

  meta = {
    description = "Terminal-based coding agent with multi-model support";
    homepage = "https://github.com/earendil-works/pi";
    changelog = "https://github.com/earendil-works/pi/releases/tag/v${version}";
    license = lib.licenses.mit;
    sourceProvenance = with lib.sourceTypes; [
      binaryBytecode
      binaryNativeCode
    ];
    platforms = builtins.attrNames releases;
    mainProgram = "pi";
  };
}
