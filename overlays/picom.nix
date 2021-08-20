self: super: rec {
  picom = super.picom.overrideAttrs (old: rec {
    version = "8.3-ibhagwan-next";

    src = super.fetchFromGitHub {
      owner = "ibhagwan";
      repo = "picom";
      rev = "0539616";
      sha256 = "sha256-1dD+pNYmJMd1g1i0aA40oegoP6z5Vl2LSLT4ttPsofw=";
      fetchSubmodules = true;
    };
  });
}
