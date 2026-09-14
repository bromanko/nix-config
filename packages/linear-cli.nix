{
  lib,
  stdenv,
  fetchurl,
  unzip,
  patchelf,
}:

let
  version = "2.0.0";

  sources = {
    aarch64-darwin = {
      artifact = "linear-aarch64-apple-darwin.tar.xz";
      sha256 = "121fe1eee6d90b22e76e4e98cbb624474eecd970a4a4c622fd4d50889b57dacc";
      binary = "linear";
    };
    x86_64-darwin = {
      artifact = "linear-x86_64-apple-darwin.tar.xz";
      sha256 = "729e67166c5094c895150b672cd3a4461fa899897e1f24dbcd07c13bb3b48c13";
      binary = "linear";
    };
    aarch64-linux = {
      artifact = "linear-aarch64-unknown-linux-gnu.tar.xz";
      sha256 = "6c3afdd11c7c0fb90053d4b53b27252b5c35bb75c679383234bef20a25558eac";
      binary = "linear";
    };
    x86_64-linux = {
      artifact = "linear-x86_64-unknown-linux-gnu.tar.xz";
      sha256 = "affb594672c2f220cef68fa7cfeb813945c4010789a4b8cc2c0e46468feb7870";
      binary = "linear";
    };
    x86_64-windows = {
      artifact = "linear-x86_64-pc-windows-msvc.zip";
      sha256 = "f1055b96a70c8bb403ca34b65283986b1d6bc9830e27c5f3571106db5dd92715";
      binary = "linear.exe";
    };
  };

  source =
    sources.${stdenv.hostPlatform.system}
      or (throw "linear-cli is not packaged for ${stdenv.hostPlatform.system}");

  isZip = lib.hasSuffix ".zip" source.artifact;
in
stdenv.mkDerivation {
  pname = "linear-cli";
  inherit version;

  src = fetchurl {
    url = "https://github.com/schpet/linear-cli/releases/download/v${version}/${source.artifact}";
    sha256 = source.sha256;
  };

  nativeBuildInputs =
    lib.optionals isZip [ unzip ] ++ lib.optionals stdenv.hostPlatform.isLinux [ patchelf ];

  buildInputs = lib.optionals stdenv.hostPlatform.isLinux [
    stdenv.cc.cc.lib
  ];

  dontConfigure = true;
  dontBuild = true;
  # linear-cli is shipped as a Deno standalone executable. Keep the embedded
  # application payload intact; stripping removes the appended data and the
  # runtime exits with "Could not find standalone binary section."
  dontStrip = true;

  postFixup = lib.optionalString stdenv.hostPlatform.isLinux ''
    # Patch the generic Linux binary for NixOS. patchelf appends new ELF
    # metadata after Deno's standalone payload, so after patching restore a
    # pristine copy of the d3n0l4nd-delimited payload at EOF.
    raw_binary="${source.binary}"
    patched_binary="$out/bin/${source.binary}"

    patchelf \
      --set-interpreter ${stdenv.cc.bintools.dynamicLinker} \
      --set-rpath ${lib.makeLibraryPath [ stdenv.cc.cc.lib ]} \
      "$patched_binary"

    mapfile -t magic_offsets < <(grep -abo 'd3n0l4nd' "$raw_binary" | cut -d: -f1)

    if [ "''${#magic_offsets[@]}" -lt 2 ]; then
      echo "failed to locate Deno standalone payload in $raw_binary" >&2
      exit 1
    fi

    section_start="''${magic_offsets[$((''${#magic_offsets[@]} - 2))]}"
    tail -c +$((section_start + 1)) "$raw_binary" >> "$patched_binary"
  '';

  installPhase = ''
    runHook preInstall

    mkdir -p "$out/bin"
    install -m755 ${source.binary} "$out/bin/${source.binary}"

    if [ "${source.binary}" != "linear" ]; then
      ln -s ${source.binary} "$out/bin/linear"
    fi

    runHook postInstall
  '';

  meta = {
    description = "CLI tool for Linear.app";
    homepage = "https://github.com/schpet/linear-cli";
    license = lib.licenses.mit;
    mainProgram = "linear";
    platforms = builtins.attrNames sources;
  };
}
