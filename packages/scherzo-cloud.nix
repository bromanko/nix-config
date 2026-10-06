{
  autoPatchelfHook,
  cacert,
  fetchurl,
  lib,
  makeWrapper,
  stdenv,
  stdenvNoCC,
  versionCheckHook,
}:

let
  version = "0.57.0";
  releases = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-pPX5vts/akVw3i2JjJpLttErbJzWKCq0afQ9BWLaFO4=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-+eHU5fwRJrg5hVupGzgSPf4heUTZeBd/p4KihxdWm18=";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-jDPnE+2W6J8v/xjS8n1ICHXVzAN987dg17wJYZOyxuU=";
    };
  };
  release =
    releases.${stdenvNoCC.hostPlatform.system}
      or (throw "unsupported Scherzo Cloud platform: ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "um";
  inherit version;

  src = fetchurl {
    url = "https://github.com/useful-machinery/um/releases/download/v${version}/um-${version}-${release.target}.tar.gz";
    inherit (release) hash;
  };

  strictDeps = true;
  dontConfigure = true;
  dontBuild = true;
  dontStrip = true;

  nativeBuildInputs = [
    makeWrapper
  ]
  ++ lib.optionals stdenvNoCC.hostPlatform.isLinux [ autoPatchelfHook ];
  buildInputs = lib.optionals stdenvNoCC.hostPlatform.isLinux [ stdenv.cc.cc.lib ];

  installPhase = ''
    runHook preInstall

    install -D -m 0755 um "$out/libexec/um/um"
    mkdir -p "$out/bin"
    # Patch the ELF interpreter instead of invoking ld-linux explicitly.
    # Runner child guards re-exec current_exe(), which must identify Scherzo.
    makeWrapper "$out/libexec/um/um" "$out/bin/um" \
      --set SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt"

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";
  postInstallCheck = ''
    test "$("$out/bin/um" --version)" = "um ${version}"

    # A version probe alone misses wrappers that break the re-executed child
    # guard. Exercise a command workflow without network or provider credentials.
    mkdir -p "$TMPDIR/runner-smoke/source" "$TMPDIR/runner-smoke/work"
    cat > "$TMPDIR/runner-smoke/source/check.yaml" <<'YAML'
    schemaVersion: 1
    steps:
      check:
        kind: cmd
        command:
          argv: [sh, -c, "exit 0"]
    YAML
    "$out/bin/um" workflow run \
      --source-root "$TMPDIR/runner-smoke/source" \
      --execution-root "$TMPDIR/runner-smoke/work" \
      --run-dir "$TMPDIR/runner-smoke/result" \
      --plain "$TMPDIR/runner-smoke/source/check.yaml"
  '';

  meta = {
    description = "Command-line interface and runner for Useful Machinery";
    homepage = "https://github.com/useful-machinery/um";
    license = lib.licenses.asl20;
    mainProgram = "um";
    platforms = builtins.attrNames releases;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
