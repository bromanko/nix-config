final: prev: {
  gemini-cli = prev.gemini-cli.overrideAttrs (oldAttrs: rec {
    version = "0.18.4";

    src = prev.fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      rev = "v${version}";
      hash = "sha256-TSHL3X+p74yFGTNFk9r4r+nnul2etgVdXxy8x9BjsRg=";
    };

    npmDepsHash = "sha256-JvzrbyiJHbKNRHoGll7eSH4dD6Hj5qnrh4F/upHPntI=";
  });
}
