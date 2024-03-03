self: super: rec {
  jujutsu = super.rustPlatform.buildRustPackage rec {
    pname = "jujutsu";
    version = "0.14.0";

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

    cargoBuildFlags = [ "--bin" "jj" ]; # don't install the fake editors
    useNextest = true; # nextest is the upstream integration framework
    ZSTD_SYS_USE_PKG_CONFIG = "1"; # disable vendored zlib
    LIBSSH2_SYS_USE_PKG_CONFIG = "1"; # disable vendored libssh2

    nativeBuildInputs = with super; [ gzip installShellFiles pkg-config ];

    buildInputs = with super;
      [ openssl zstd libgit2 libssh2 ] ++ lib.optionals stdenv.isDarwin [
        darwin.apple_sdk.frameworks.Security
        darwin.apple_sdk.frameworks.SystemConfiguration
        libiconv
      ];

    postInstall = ''
      $out/bin/jj util mangen > ./jj.1
      installManPage ./jj.1

      installShellCompletion --cmd jj \
        --bash <($out/bin/jj util completion bash) \
        --fish <($out/bin/jj util completion fish) \
        --zsh <($out/bin/jj util completion zsh)
    '';

    passthru = {
      updateScript = super.nix-update-script { };
      tests = {
        version = super.testers.testVersion {
          package = jujutsu;
          command = "jj --version";
        };
      };
    };

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
