final: prev: {
  gemini-cli = prev.gemini-cli.overrideAttrs (oldAttrs: rec {
    version = "0.16.0";

    src = prev.fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      rev = "v${version}";
      hash = "sha256-EOiG7Ov+tY6UPci4A67kKcCItkTrrENOm1mSaWxKE94=";
    };

    npmDepsHash = "sha256-JvzrbyiJHbKNRHoGll7eSH4dD6Hj5qnrh4F/upHPntI=";
  });
}
