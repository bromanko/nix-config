{
  lib,
  stdenvNoCC,
  fetchurl,
  unzip,
}:

let
  version = "2.27.6";

  assets = {
    aarch64-darwin = {
      file = "coder_${version}_darwin_arm64.zip";
      hash = "sha256-EfAtIb+cwID9K4MujMAfwx8Ro+kBEN8eiHx2E46pcgo=";
    };
    x86_64-darwin = {
      file = "coder_${version}_darwin_amd64.zip";
      hash = "sha256-NsSMJdmA+JCT+vCRKUur4PW8vPBETGEFAAWIRjI5qu0=";
    };
    x86_64-linux = {
      file = "coder_${version}_linux_amd64.tar.gz";
      hash = "sha256-dfPZpceu6gdfnAJarKl0VLI6dcoBVQ/mCP+TCzTu2RA=";
    };
    aarch64-linux = {
      file = "coder_${version}_linux_arm64.tar.gz";
      hash = "sha256-38WnGjrDzgswGCqNUJXrlyQvKhmuCfTTRnbDK7ni4no=";
    };
  };

  system = stdenvNoCC.hostPlatform.system;
  asset = assets.${system} or (throw "Unsupported system for coder package: ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "coder";
  inherit version;

  src = fetchurl {
    url = "https://github.com/coder/coder/releases/download/v${version}/${asset.file}";
    hash = asset.hash;
  };

  nativeBuildInputs = [ unzip ];

  dontUnpack = true;

  installPhase = ''
    runHook preInstall

    mkdir -p extracted

    case "${asset.file}" in
      *.zip)
        unzip -q "$src" -d extracted
        ;;
      *.tar.gz)
        tar -xzf "$src" -C extracted
        ;;
      *)
        echo "Unsupported archive type: ${asset.file}" >&2
        exit 1
        ;;
    esac

    coder_bin=$(find extracted -type f -name coder | head -n 1)
    if [ -z "$coder_bin" ]; then
      echo "Could not find coder binary in archive" >&2
      exit 1
    fi

    install -Dm755 "$coder_bin" "$out/bin/coder"

    mkdir -p "$out/share/fish/vendor_completions.d"
    "$out/bin/coder" completion --shell fish --print > "$out/share/fish/vendor_completions.d/coder.fish" || true

    runHook postInstall
  '';

  meta = {
    description = "Coder CLI";
    homepage = "https://github.com/coder/coder";
    license = lib.licenses.agpl3Only;
    mainProgram = "coder";
    platforms = builtins.attrNames assets;
  };
}
