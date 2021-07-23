self: super: rec {
  emacsMacport = super.emacsMacport.overrideAttrs (old: rec {
    version = "27.2";
    emacsName = "emacs-${version}";

    macportVersion = "8.2";
    name = "emacs-mac-${version}-${macportVersion}";

    src = super.fetchurl {
      url = "mirror://gnu/emacs/${emacsName}.tar.xz";
      sha256 = "tKfMTnjmPzeGJOCRkhW5EK9bsqCvyBn60pgnLp9Awbk=";
    };

    macportSrc = super.fetchurl {
      url =
        "ftp://ftp.math.s.chiba-u.ac.jp/emacs/${emacsName}-mac-${macportVersion}.tar.gz";
      sha256 = "6iclooc+8jOqF8et5M+z8nes8ffV8iNokDMfP8cT9a0=";
    };
    configureFlags = old.configureFlags ++ [ "--with-mac-metal" ];
  });
}
