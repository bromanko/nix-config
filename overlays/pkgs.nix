# My own custom packages
self: super: {
  zsh-vim-mode = super.stdenv.mkDerivation rec {
    pname = "zsh-vim-mode";
    version = "HEAD";

    src = super.fetchFromGitHub {
      owner = "softmoth";
      repo = "zsh-vim-mode";
      rev = "1f9953b";
      sha256 = "a+6EWMRY1c1HQpNtJf5InCzU7/RphZjimLdXIXbO6cQ=";
    };

    dontConfigure = true;
    dontBuild = true;

    installPhase = ''
      install -Dm0644 zsh-vim-mode.plugin.zsh $out/share/zsh/plugins/zsh-vim-mode/zsh-vim-mode.plugin.zsh
    '';

    meta = with super.lib; {
      description = "Friendly bindings for ZSH's vi mode";
      homepage = "https://github.com/softmoth/zsh-vim-mode";
      license = licenses.mit;
      maintainers = with maintainers; [ bromanko ];
      platforms = platforms.linux ++ platforms.darwin;
    };
  };

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
