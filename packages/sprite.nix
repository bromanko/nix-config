{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  version = "0.0.1-rc30";

  sources = {
    aarch64-darwin = {
      url = "https://sprites-binaries.t3.storage.dev/client/v${version}/sprite-darwin-arm64.tar.gz";
      hash = "sha256-uvPa/CRS2HVdU35aLHd5s4Uj3iL2zWy+pMJ8BLgpRss=";
    };
    x86_64-darwin = {
      url = "https://sprites-binaries.t3.storage.dev/client/v${version}/sprite-darwin-amd64.tar.gz";
      hash = "sha256-i2Lwr69Ca8o+3KgbSiR9K0IQSRvu9M3Nr+bVc1y7V1o=";
    };
    aarch64-linux = {
      url = "https://sprites-binaries.t3.storage.dev/client/v${version}/sprite-linux-arm64.tar.gz";
      hash = "sha256-GaOM73Zs/s9F6nFKk1aKxbcqDhdauAlIzMkJMl31DRI=";
    };
    x86_64-linux = {
      url = "https://sprites-binaries.t3.storage.dev/client/v${version}/sprite-linux-amd64.tar.gz";
      hash = "sha256-m29BkphwYRM6j7aqigzCEgLazneZzoFCQBEqpyERgwU=";
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
