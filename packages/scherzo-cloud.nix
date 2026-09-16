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
  version = "0.35.1";
  releases = {
    aarch64-darwin = {
      target = "aarch64-apple-darwin";
      hash = "sha256-Q8jqGCSU3OnQxFh/IocJjqhAmQSfPJwEtNYs768u7QY=";
    };
    aarch64-linux = {
      target = "aarch64-unknown-linux-gnu";
      hash = "sha256-KVJgvn1xzyROvVzc0Wmrk0ljFnPOiRzuCGlq43ZugIM=";
    };
    x86_64-linux = {
      target = "x86_64-unknown-linux-gnu";
      hash = "sha256-Nw/AQrbRDVW1y3Jp69Di4Vh52nUOw08ln0o7Mi1FJCc=";
    };
  };
  release =
    releases.${stdenvNoCC.hostPlatform.system}
      or (throw "unsupported Scherzo Cloud platform: ${stdenvNoCC.hostPlatform.system}");
in
stdenvNoCC.mkDerivation {
  pname = "scherzo-cloud";
  inherit version;

  src = fetchurl {
    url = "https://github.com/scherzo-systems/scherzo-cloud-cli/releases/download/v${version}/scherzo-cloud-${version}-${release.target}.tar.gz";
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

    install -D -m 0755 scherzo-cloud "$out/libexec/scherzo-cloud/scherzo-cloud"
    mkdir -p "$out/bin"
    # Patch the ELF interpreter instead of invoking ld-linux explicitly.
    # Runner child guards re-exec current_exe(), which must identify Scherzo.
    makeWrapper "$out/libexec/scherzo-cloud/scherzo-cloud" "$out/bin/scherzo-cloud" \
      --set SSL_CERT_FILE "${cacert}/etc/ssl/certs/ca-bundle.crt"

    runHook postInstall
  '';

  doInstallCheck = true;
  nativeInstallCheckInputs = [ versionCheckHook ];
  versionCheckProgramArg = "--version";
  postInstallCheck = ''
    test "$("$out/bin/scherzo-cloud" --version)" = "scherzo-cloud ${version}"

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
    "$out/bin/scherzo-cloud" workflow run \
      --source-root "$TMPDIR/runner-smoke/source" \
      --execution-root "$TMPDIR/runner-smoke/work" \
      --run-dir "$TMPDIR/runner-smoke/result" \
      --plain "$TMPDIR/runner-smoke/source/check.yaml"
  '';

  meta = {
    description = "Command-line interface and runner for Scherzo Cloud";
    homepage = "https://github.com/scherzo-systems/scherzo-cloud-cli";
    license = lib.licenses.asl20;
    mainProgram = "scherzo-cloud";
    platforms = builtins.attrNames releases;
    sourceProvenance = with lib.sourceTypes; [ binaryNativeCode ];
  };
}
