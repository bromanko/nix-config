{
  lib,
  stdenvNoCC,
  fetchurl,
}:

let
  artifacts = {
    "aarch64-darwin" = {
      platform = "aarch64-apple-darwin";
      hash = "sha256-AqB7BfKUW8Pp+qNaMnJJcQ32Ww39zaC1PcSV457XgV8=";
    };
    "x86_64-darwin" = {
      platform = "x86_64-apple-darwin";
      hash = "sha256-vwO3r/lMltbDQvrwJ/kHzvnAb0AXKr5TDVmnAsDE8+k=";
    };
    "aarch64-linux" = {
      platform = "aarch64-unknown-linux-musl";
      hash = "sha256-nOtfKs4TIwFkBpxIehSraz26ahYQbGPLm9/Na+IgStU=";
    };
    "x86_64-linux" = {
      platform = "x86_64-unknown-linux-musl";
      hash = "sha256-2lWOHDQ77XcUtYQLn7any4ngyzkVL9lyM/T6/Yp7kio=";
    };
  };
  system = stdenvNoCC.hostPlatform.system;
  artifact = artifacts.${system} or (throw "SecretSpec 0.21 is unavailable for ${system}");
in
stdenvNoCC.mkDerivation {
  pname = "secretspec";
  version = "0.21.0";

  src = fetchurl {
    url = "https://github.com/cachix/secretspec/releases/download/v0.21.0/secretspec-${artifact.platform}.tar.xz";
    inherit (artifact) hash;
  };
  sourceRoot = "secretspec-${artifact.platform}";

  dontConfigure = true;
  dontBuild = true;

  installPhase = ''
    runHook preInstall
    mkdir -p "$out/bin"
    install -m 0755 secretspec docker-credential-secretspec git-credential-secretspec "$out/bin/"
    runHook postInstall
  '';

  meta = {
    description = "Declarative secrets, every environment, any provider";
    homepage = "https://secretspec.dev";
    license = lib.licenses.asl20;
    platforms = builtins.attrNames artifacts;
    mainProgram = "secretspec";
  };
}
