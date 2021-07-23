self: super: rec {
  fantasque-sans-mono-nerd-font = super.stdenv.mkDerivation rec {
    name = "fantasque-sans-mono-nerd-font";
    version = "HEAD";

    src = super.fetchFromGitHub {
      owner = "buzzkillhardball";
      repo = "nerdfonts";
      rev = "f401a7cd7d0b2959cdf286ff0f7601e244571790";
      sha256 = "hjeAp3j2FDqJz30Fe1qLBUzy1/apiSiXm3TFO+fobYI=";
    };

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      dest=$out/share/fonts/truetype
      ls -al
      install -m 444 -Dt $dest "patched-fonts/FantasqueSansMono/Bold-Italic/complete/Fantasque Sans Mono Bold Italic Nerd Font Complete Mono.ttf"
      install -m 444 -Dt $dest "patched-fonts/FantasqueSansMono/Bold/complete/Fantasque Sans Mono Bold Nerd Font Complete Mono.ttf"
      install -m 444 -Dt $dest "patched-fonts/FantasqueSansMono/Italic/complete/Fantasque Sans Mono Italic Nerd Font Complete Mono.ttf"
      install -m 444 -Dt $dest "patched-fonts/FantasqueSansMono/Regular/complete/Fantasque Sans Mono Regular Nerd Font Complete Mono.ttf"
    '';

    meta = with super.lib; {
      description = "Nerd Font patched version of the Fantasque Sans Mono font";
      homepage = "https://github.com/buzzkillhardball/nerdfonts";
      license = licenses.mit;
      maintainers = with maintainers; [ bromanko ];
      platforms = platforms.linux ++ platforms.darwin;
    };
  };
}
