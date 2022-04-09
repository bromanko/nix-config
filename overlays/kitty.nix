self: super: rec {
  kitty = super.kitty.overrideAttrs (old: rec {
    version = "0.24.0";

    src = super.fetchFromGitHub {
      owner = "kovidgoyal";
      repo = "kitty";
      rev = "v${version}";
      sha256 = "sha256-w5debDPQ5y6Aib7mg7JSPBMnErLSF2bUl94wt58NDF0=";
    };

    buildInputs = old.buildInputs ++ [ super.pkgs.librsync ];

    # TODO This should only be set for aarch64
    preBuild = "MACOSX_DEPLOYMENT_TARGET=10.16";
  });
}
