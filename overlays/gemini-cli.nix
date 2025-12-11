final: prev: {
  gemini-cli = prev.gemini-cli.overrideAttrs (oldAttrs: rec {
    version = "0.20.0";

    src = prev.fetchFromGitHub {
      owner = "google-gemini";
      repo = "gemini-cli";
      rev = "v${version}";
      hash = "sha256-6+fT9/npYrngAPeAP7pA6DYNuCVWm1lKpSVP4Ux4ddw=";
    };

    npmDeps = prev.fetchNpmDeps {
      inherit src;
      hash = "sha256-wbr/9IitwQxBVFskCyGZfWy6FmIGZAVYLbF/sMJ2X+s=";
    };

    # npmDepsHash = "sha256-wbr/9IitwQxBVFskCyGZfWy6FmIGZAVYLbF/sMJ2X+s=";
  });
}
