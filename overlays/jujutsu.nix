self: super:
let
  ourRustVersion = super.rust-bin.stable."1.76.0".default;

  ourRustPlatform = super.makeRustPlatform {
    rustc = ourRustVersion;
    cargo = ourRustVersion;
  };

  # these are needed in both devShell and buildInputs
  darwinDeps = with super;
    lib.optionals stdenv.isDarwin [
      darwin.apple_sdk.frameworks.Security
      darwin.apple_sdk.frameworks.SystemConfiguration
      libiconv
    ];

  # work around https://github.com/nextest-rs/nextest/issues/267
  # this needs to exist in both the devShell and preCheck phase!
  darwinNextestHack = super.lib.optionalString super.stdenv.isDarwin ''
    export DYLD_FALLBACK_LIBRARY_PATH=$(${ourRustVersion}/bin/rustc --print sysroot)/lib
  '';

  # NOTE (aseipp): on Linux, go ahead and use mold by default to improve
  # link times a bit; mostly useful for debug build speed, but will help
  # over time if we ever get more dependencies, too
  useMoldLinker = super.stdenv.isLinux;

  # these are needed in both devShell and buildInputs
  linuxNativeDeps = with super; lib.optionals stdenv.isLinux [ mold-wrapped ];
in rec {
  jujutsu = ourRustPlatform.buildRustPackage rec {
    pname = "jujutsu";
    version = "unstable-${self.shortRev or "dirty"}";

    buildFeatures = [ "packaging" ];
    cargoBuildFlags =
      [ "--bin" "jj" ]; # don't build and install the fake editors
    useNextest = true;

    src = super.fetchFromGitHub {
      owner = "bnjmnt4n";
      repo = "jj";
      rev = "0ac9d29ab3cab3c6d2db41f64e384d2832fb34cc"; # ssh-openssh branch
      sha256 = "sha256-pcLhHp+5R7rp+M2VN6p4XIHiGLOk5iH2CjD0fP1tI+s=";
    };

    cargoLock = {
      lockFile = ./jujutsu/Cargo.lock;
      allowBuiltinFetchGit = true;
    };

    nativeBuildInputs = with super;
      [
        gzip
        installShellFiles
        makeWrapper
        pkg-config

        # for signing tests
        gnupg
        openssh
      ] ++ linuxNativeDeps;
    buildInputs = with super; [ openssl zstd libgit2 libssh2 ] ++ darwinDeps;

    ZSTD_SYS_USE_PKG_CONFIG = "1";
    LIBSSH2_SYS_USE_PKG_CONFIG = "1";
    RUSTFLAGS =
      super.lib.optionalString useMoldLinker "-C link-arg=-fuse-ld=mold";
    NIX_JJ_GIT_HASH = self.rev or "";
    CARGO_INCREMENTAL = "0";

    preCheck = ''
      export RUST_BACKTRACE=1
    '' + darwinNextestHack;

    postInstall = ''
      $out/bin/jj util mangen > ./jj.1
      installManPage ./jj.1

      installShellCompletion --cmd jj \
        --bash <($out/bin/jj util completion bash) \
        --fish <($out/bin/jj util completion fish) \
        --zsh <($out/bin/jj util completion zsh)
    '';

    meta = with super.lib; {
      description = "A Git-compatible DVCS that is both simple and powerful";
      homepage = "https://github.com/martinvonz/jj";
      changelog =
        "https://github.com/martinvonz/jj/blob/v${version}/CHANGELOG.md";
      license = licenses.asl20;
      maintainers = with maintainers; [ _0x4A6F thoughtpolice ];
      mainProgram = "jj";
    };
  };
}
