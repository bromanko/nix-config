{
  lib,
  stdenv,
  rustPlatform,
  fetchFromGitHub,
  apple-sdk_11,
}:
rustPlatform.buildRustPackage rec {
  pname = "rift";
  version = "unstable-2025-01-10";

  src = fetchFromGitHub {
    owner = "acsandmann";
    repo = "rift";
    rev = "c0b2846b3342bcaa92a293453e35a092fe490aa4";
    hash = "sha256-mzALi9iAQv08FHNQTzOx6JteMz9TmQrSbFhKCKtAJkE=";
  };

  cargoHash = "sha256-41QUCNIsbg1mYzJgaMUPKY1jfn9m6a5XzGz9dqYS3eE=";

  buildInputs = lib.optionals stdenv.isDarwin [
    apple-sdk_11
  ];

  # Enable unstable Rust features (let_chains, stmt_expr_attributes)
  RUSTC_BOOTSTRAP = 1;

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
