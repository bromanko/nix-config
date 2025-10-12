{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  darwin,
}:
rustPlatform.buildRustPackage rec {
  pname = "rift";
  version = "unstable-2025-01-10";

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    rev = "main";
    hash = lib.fakeHash;
  };

  cargoHash = lib.fakeHash;

  buildInputs = [
    darwin.apple_sdk.frameworks.AppKit
    darwin.apple_sdk.frameworks.ApplicationServices
  ];

  # Disable tests - may require GUI/accessibility
  doCheck = false;

  meta = {
    description = "Tiling window manager for macOS";
    homepage = "https://github.com/acsandmann/rift";
    license = lib.licenses.mit;
    platforms = lib.platforms.darwin;
    mainProgram = "rift";
  };
}
