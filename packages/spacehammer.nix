{
  lib,
  stdenv,
  fetchFromGitHub,
  ...
}:

let
  pname = "spacehammer";
  version = "1a0526c";
in
stdenv.mkDerivation {
  inherit pname version;

  src = fetchFromGitHub {
    owner = "agzam";
    repo = "spacehammer";
    rev = version;
    sha256 = "sha256-6r7uzC3CkxWSpJ/iAL9V0KaQuNyxX8z9w7ICMmibPtI=";
  };

  dontBuild = true;
  installPhase = ''
    mkdir -p $out
    cp -R * $out
  '';

  meta = with lib; {
    homepage = "https://github.com/agzam/spacehammer";
    description = "Hammerspoon config inspired by Spacemacs";
    license = licenses.mit;
    platforms = platforms.darwin;
    maintainers = [ maintainers.agzam ];
  };
}
