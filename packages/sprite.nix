{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.0.1-rc29";

  sources = {
    aarch64-darwin = {
      url = "https://sprites-binaries.t3.storage.dev/client/v${version}/sprite-darwin-arm64.tar.gz";
      hash = "sha256-HyEHGQF0S9BaKp80jZ8NzcwgtUFGrmycs5cJbCJJTs8=";
    };
    x86_64-darwin = {
      url = "https://sprites-binaries.t3.storage.dev/client/v${version}/sprite-darwin-amd64.tar.gz";
      hash = "sha256-dJLI0Cn+8MhOtf7Id6/PnlxzfY4ZhiFOwgjnpABmE6U=";
    };
    aarch64-linux = {
      url = "https://sprites-binaries.t3.storage.dev/client/v${version}/sprite-linux-arm64.tar.gz";
      hash = "sha256-PECd9HjRFNLMfVBEvNZhyU1JsRdwOY2hmaOdyq4Qd9Y=";
    };
    x86_64-linux = {
      url = "https://sprites-binaries.t3.storage.dev/client/v${version}/sprite-linux-amd64.tar.gz";
      hash = "sha256-4AVjv/ZWM4QYmOJFz9/ky1w3cO9Vc93TqrRWhrc1fP4=";
    };
  };

  platform = stdenvNoCC.hostPlatform.system;
  source = sources.${platform} or (throw "Unsupported platform: ${platform}");
in
stdenvNoCC.mkDerivation {
  pname = "sprite";
  inherit version;

  src = fetchurl {
    inherit (source) url hash;
  };

  sourceRoot = ".";

  unpackPhase = ''
    tar -xzf $src
  '';

  installPhase = ''
    install -Dm755 sprite $out/bin/sprite
  '';

  meta = {
    description = "CLI for Sprites - durable, interactive cloud sandboxes by Fly.io";
    homepage = "https://sprites.dev";
    license = lib.licenses.unfree;
    platforms = builtins.attrNames sources;
    mainProgram = "sprite";
  };
}
