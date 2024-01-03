{ lib, stdenv, fetchzip, ... }:

let
  name = "websters-1913";
  version = "1.0.0";
in stdenv.mkDerivation {
  inherit name version;

  src = fetchzip {
    url =
      "https://github.com/cmod/websters-1913/raw/main/websters-1913.dictionary.zip";
    sha256 = "sha256-t3BFMmOKla34yA8f0EyRVvE2FZHEjN7X93UQIgaXol8=";
    stripRoot = false;
  };

  dontBuild = true;
  installPhase = ''
    local webDir="$out/websters-1913.dictionary"
    install -m755 -d "$webDir"
    cp -r websters-1913.dictionary/** "$webDir"
    chmod -R 755 $webDir
  '';

  meta = with lib; {
    homepage = "https://github.com/cmod/websters-1913";
    description =
      "A contemporary-update to the CSS styling of dictionary results for the Webster's 1913 English Dictionary.";
    license = licenses.publicDomain;
    platforms = platforms.darwin;
    maintainers = [ ];
  };
}
